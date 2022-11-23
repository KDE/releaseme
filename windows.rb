#!/usr/bin/env ruby
# frozen_string_literal: true

# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2022 Harald Sitter <sitter@kde.org>

require 'awesome_print'
require 'faraday'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'json'
require 'uri'
require 'reverse_markdown'
require 'tty/command'
require 'open-uri'
require 'azure/storage/blob'
require 'azure/storage/common'

require_relative 'appdata'

# --- CREATE NEW SUBMISSION DATA
# https://docs.microsoft.com/en-us/windows/uwp/monetize/manage-app-submissions#app-submission-object
BaseListing = Struct.new(
  :copyrightAndTrademarkInfo,
  :keywords,
  :licenseTerms,
  :privacyPolicy,
  :supportContact,
  :websiteUrl,
  :description,
  :features,
  :releaseNotes,
  :recommendedHardware,
  :minimumHardware,
  :title,
  :shortDescription,
  :shortTitle,
  :sortTitle,
  :voiceTitle,
  :devStudio,
  :images
) do
  def initialize(*)
    super
    @copyrightAndTrademarkInfo = ''
    @keywords = []
    @licenseTerms = ''
    @privacyPolicy = ''
    @supportContact = ''
    @websiteUrl = ''
    @description = ''
    @features = []
    @releaseNotes = ''
    @recommendedHardware = []
    @minimumHardware = []
    @shortDescription = ''
    @shortTitle = ''
    @sortTitle = ''
    @voiceTitle = ''
    @devStudio = ''
    @images = []
  end
  def to_json(*args)
    to_h.to_json(*args)
  end
end
Listing = Struct.new(
  :baseListing,
  :platformOverrides
) do
  def to_json(*args)
    to_h.to_json(*args)
  end
end

TITLES = {
  'org.kde.filelight' => 'Filelight',
  'org.kde.kstars' => 'KStars'
}.freeze

class WindowsRelease
  attr_reader :appstream_id, :factory_job, :artifacts_dir, :upload_dir

  def initialize(appstream_id:, factory_job:)
    @appstream_id = appstream_id
    @factory_job = factory_job

    @artifacts_dir = File.absolute_path("#{appstream_id}.windows-artifacts")
    @upload_dir = File.absolute_path("#{appstream_id}.windows-upload")

    FileUtils.rm_rf(artifacts_dir)
    Dir.mkdir(artifacts_dir)

    FileUtils.rm_rf(upload_dir)
    Dir.mkdir(upload_dir)
  end

  def microsoftonline
    @microsoftonline ||= Faraday.new('https://login.microsoftonline.com') do |c|
      c.response :json
      c.use Faraday::Response::RaiseError
      c.use Faraday::Response::Logger
      # c.request :multipart
      c.request :url_encoded
      c.adapter :excon
    end
  end

  def access_token
    @access_token ||= begin
      tenant_id = '__________________'
      response = microsoftonline.post("/#{tenant_id}/oauth2/token",
                                      grant_type: 'client_credentials',
                                      client_id: '__________________',
                                      client_secret: '__________________',
                                      resource: 'https://manage.devcenter.microsoft.com')
      response.body['access_token']
    end
  end

  def devcenter
    @devcenter ||= Faraday.new('https://manage.devcenter.microsoft.com') do |c|
      c.request :json
      c.response :json
      c.use Faraday::Response::RaiseError
      c.use Faraday::Response::Logger
      c.request :url_encoded
      c.request :authorization, 'Bearer', access_token
      c.adapter :excon
      c.request :multipart
    end
  end

  def download_build
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("wget https://binary-factory.kde.org/job/#{factory_job}/lastSuccessfulBuild/artifact/*zip*/archive.zip") || raise
        system('unzip archive.zip') || raise
        system('tree') || raise
        FileUtils.cp(Dir.glob('archive/*'), artifacts_dir, verbose: true)
      end
    end
  end

  def release
    appdata = JSON.parse(URI.open("https://apps.kde.org/appdata/#{appstream_id}.json").read)
    store_id = File.basename(URI.parse(appdata.fetch('Custom').fetch('KDE::windows_store')).path)

    download_build

    # --- CANCEL PENDING SUBMISSION AND CREATE NEW ONE
    response = devcenter.get("/v1.0/my/applications/#{store_id}")
    body = response.body
    if body.key?('pendingApplicationSubmission')
      id = body.fetch('pendingApplicationSubmission').fetch('id')
      devcenter.delete("/v1.0/my/applications/#{store_id}/submissions/#{id}")
    end
    last_submission_id = body.fetch('lastPublishedApplicationSubmission').fetch('id')

    response = devcenter.get("/v1.0/my/applications/#{store_id}/submissions/#{last_submission_id}")
    last_submission = response.body

    # https://docs.microsoft.com/en-us/windows/uwp/publish/supported-languages
    # appstream to microsoft
    language_mapping = {
      'en' => 'en-us', # the apps.kde.org appdata is actually a bit mangled the real key would be C not 'en'
      'sr' => 'sr-cyrl',
      'sr-la' => 'sr-Latn', # preserve capital letter (by default we downcase)
      'ca-va' => 'ca-es-valencia',
      'az' => 'az-arab'
    }

    # some SR variants are not a thing outside the KDE bubble
    # ia and ast are not supported by microsoft
    language_skip_list = %w[x-test sr-ijekavian sr-ijekavianlatin ia ast sr-ije sr-il]

    global_listings = {}
    listings = {}
    appdata.fetch('Name').each do |lang, value|
      next if language_skip_list.include?(lang)

      global_listing = Listing.new(BaseListing.new, {})
      global_listings[language_mapping.fetch(lang, lang)] = global_listing
      listing = global_listing.baseListing
      listing.title = TITLES.fetch(appstream_id) # titles must be reserved :((
      listings[language_mapping.fetch(lang, lang)] = listing
    end

    listings.each do |lang, listing|
      appdata_lang = language_mapping.key(lang) || lang
      listing.description = ReverseMarkdown.convert(appdata.fetch('Description').fetch(appdata_lang, ''))

      listing.keywords = appdata.fetch('Keywords', {}).fetch(appdata_lang, [])
      listing.images = last_submission.fetch('listings')[lang]&.fetch('baseListing')&.fetch('images')

      # Images mustn't be empty!
      if !listing.images || listing.images.empty?
        url = appdata.fetch('Screenshots').find { |x| x['default'] == true }&.fetch('source-image')&.fetch('url')
        @download_image ||= system('wget', url, chdir: upload_dir)
        listing.images = [{ 'fileName' => File.basename(url), 'fileStatus' => 'PendingUpload', 'imageType' => 'Screenshot' }]
      end

      # https://github.com/ximion/appstream/issues/388
      listing.features = last_submission.fetch('listings')[lang]&.fetch('baseListing')&.fetch('features')
    end

    listings.each do |lang, listing|
      next unless !listing.description || listing.description.empty? || !listing.images || listing.images.empty?
      raise 'en-us is invalid but may not be dropped!' if lang == 'en-us'

      global_listings.delete(lang)
      listings.delete(lang)
    end

    # listings['en-us'].images = [{"fileName"=>"Untitled.png", "fileStatus"=>"Uploaded", "id"=>"1152922700002825509", "imageType"=>"Screenshot"},
    #     {"fileName"=>"Untitl345345ed.png", "fileStatus"=>"Uploaded", "id"=>"1152922700002826100", "imageType"=>"Screenshot"}]

    Dir.chdir(artifacts_dir) do
      FileUtils.cp(Dir.glob('*.appxupload'), upload_dir, verbose: true)
    end

    application_packages = []
    Dir.chdir(upload_dir) do
      system('zip', 'blob.zip', *Dir.glob('*'))

      files = Dir.glob('*.appxupload')
      raise unless files.size == 1

      file = files[0]
      application_packages += last_submission['applicationPackages'] + [{
        # The file name is relative to the root of the uploaded ZIP file.
        'fileName' => file,
        # If you haven't begun to upload the file yet, set this value to "PendingUpload".
        'fileStatus' => 'PendingUpload'
      }]
    end

    # --- PUT NEW SUBMISSION
    response = devcenter.post("/v1.0/my/applications/#{store_id}/submissions")
    submission_id = response.body.fetch('id')
    submission = response.body

    submission['listings'] = global_listings
    submission['applicationPackages'] = application_packages

    devcenter.put("/v1.0/my/applications/#{store_id}/submissions/#{submission_id}", JSON.pretty_generate(submission))

    # --- UPLOAD DATA BLOB
    upload_url = submission['fileUploadUrl'].gsub('+', '%2B')
    upload_uri = URI.parse(upload_url)
    _, container, blob = upload_uri.path.split('/')
    sas_token = upload_uri.query
    client = Azure::Storage::Blob::BlobService.create(storage_blob_host: upload_url, storage_sas_token: sas_token)
    client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)
    client.create_block_blob(container, blob, File.binread("#{upload_dir}/blob.zip"))
    devcenter.post("/v1.0/my/applications/#{store_id}/submissions/#{submission_id}/commit")#, JSON.pretty_generate(submission))
  rescue => e
    p e
    p e.message
    p e.to_s
    p e.exception
    raise e
  end
end

require 'drb/drb'

class ReleaseServer
  def release(appstream_id:, factory_job:)
    windows = WindowsRelease.new(appstream_id: appstream_id, factory_job: factory_job)
    windows.release
  end
end

DRb.start_service("drbunix:#{Dir.home}/drb.socket", ReleaseServer.new)
DRb.thread.join

__END__

=> {"id"=>"1152921505694591307",
  "applicationCategory"=>"UtilitiesAndTools_FileManager",
  "pricing"=>
   {"trialPeriod"=>"NoFreeTrial",
    "marketSpecificPricings"=>{"LB"=>"NotAvailable"},
    "sales"=>[],
    "priceId"=>"Free",
    "isAdvancedPricingModel"=>true},
  "visibility"=>"Public",
  "targetPublishMode"=>"Immediate",
  "targetPublishDate"=>"1601-01-01T00:00:00.0000000Z",
  "listings"=>
   {"en-us"=>
     {"baseListing"=>
       {"copyrightAndTrademarkInfo"=>"",
        "keywords"=>[],
        "licenseTerms"=>"",
        "privacyPolicy"=>"",
        "supportContact"=>"",
        "websiteUrl"=>"",
        "description"=>"Filelight is an application to visualize the disk usage on your computer.",
        "features"=>
         ["Configurable color schemes",
          "File system navigation by mouse clicks",
          "Information about files and directories on hovering",
          "Files and directories can be copied or removed directly from the context menu"],
        "releaseNotes"=>"* Updated to release 20.12.2\r\n* Updated dependencies KDE Frameworks to 5.79.0 and Qt to 5.15.2",
        "images"=>
         [{"fileName"=>"Untitled.png", "fileStatus"=>"Uploaded", "id"=>"1152922700002825509", "imageType"=>"Screenshot"},
          {"fileName"=>"Untitl345345ed.png", "fileStatus"=>"Uploaded", "id"=>"1152922700002826100", "imageType"=>"Screenshot"}],
        "recommendedHardware"=>[],
        "minimumHardware"=>[],
        "title"=>"Filelight",
        "shortDescription"=>"",
        "shortTitle"=>"",
        "sortTitle"=>"",
        "voiceTitle"=>"",
        "devStudio"=>""},
      "platformOverrides"=>{}}},
  "hardwarePreferences"=>["Keyboard", "Mouse"],
  "automaticBackupEnabled"=>true,
  "canInstallOnRemovableMedia"=>true,
  "isGameDvrEnabled"=>false,
  "gamingOptions"=>
   [{"genres"=>["UtilitiesAndTools_FileManager"],
     "isLocalMultiplayer"=>false,
     "isLocalCooperative"=>false,
     "isOnlineMultiplayer"=>false,
     "isOnlineCooperative"=>false,
     "isBroadcastingPrivilegeGranted"=>true,
     "isCrossPlayEnabled"=>false,
     "kinectDataForExternal"=>"Disabled"}],
  "hasExternalInAppProducts"=>false,
  "meetAccessibilityGuidelines"=>false,
  "notesForCertification"=>"",
  "status"=>"PendingCommit",
  "statusDetails"=>
   {"errors"=>[],
    "warnings"=>
     [{"code"=>"SalesUnsupportedWarning",
       "details"=>
        "The sales resource is no longer supported. To view or edit the sales data for this submission, use the Dev Center dashboard."}],
    "certificationReports"=>[]},
  "applicationPackages"=>
   [{"fileName"=>"filelight-21.12.0-829-windows-msvc2019_64-cl.appxupload",
     "fileStatus"=>"Uploaded",
     "id"=>"2000000000063149555",
     "version"=>"21.1200.829.0",
     "architecture"=>"x64",
     "targetPlatform"=>"Windows10",
     "languages"=>["en-US"],
     "capabilities"=>["Microsoft.storeFilter.core.notSupported_8wekyb3d8bbwe", "runFullTrust"],
     "minimumDirectXVersion"=>"None",
     "minimumSystemRam"=>"None",
     "targetDeviceFamilies"=>["Windows.Desktop min version 10.0.14316.0"]}],
  "packageDeliveryOptions"=>
    {"packageRollout"=>
      {"isPackageRollout"=>false,
      "packageRolloutPercentage"=>0.0,
      "packageRolloutStatus"=>"PackageRolloutNotStarted",
      "fallbackSubmissionId"=>"0"},
    "isMandatoryUpdate"=>false,
    "mandatoryUpdateEffectiveDate"=>"1601-01-01T00:00:00.0000000Z"},
  "enterpriseLicensing"=>"Online",
  "allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies"=>true,
  "allowTargetFutureDeviceFamilies"=>{"Desktop"=>true, "Mobile"=>false, "Xbox"=>false, "Team"=>false, "Holographic"=>false, "7"=>false},
  "friendlyName"=>"Submission 5",
  "trailers"=>[]}
