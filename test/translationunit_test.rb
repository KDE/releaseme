require_relative 'lib/testme'
require_relative '../lib/releaseme/translationunit'

class TestTranslationUnit < Testme
  def create(type)
    l = ReleaseMe::TranslationUnit.new(type, 'amarok', '/dev/null')
    l.target = "#{@dir}/l10n"
    l
  end

  def create_plasma(type)
    l = ReleaseMe::TranslationUnit.new(type, 'khotkeys', 'kde-workspace')
    l.target = "#{@dir}/l10n"
    l
  end

  def create_trunk
    create(ReleaseMe::TranslationUnit::TRUNK)
  end

  def create_stable
    create(ReleaseMe::TranslationUnit::STABLE)
  end

  def create_lts
    create(ReleaseMe::TranslationUnit::LTS)
  end

  def create_lts_plasma
    create_plasma(ReleaseMe::TranslationUnit::LTS)
  end

  def test_0_attr
    l = create_trunk

    assert_equal("#{@dir}/l10n", l.target)
    assert_equal(ReleaseMe::TranslationUnit::TRUNK, l.type)
    assert_equal('/dev/null', l.i18n_path)
  end

  def test_0_repo_url_init_trunk
    l = create_trunk
    assert_equal(ReleaseMe::TranslationUnit::TRUNK, l.type)
    l.init_repo_url('file://a')
    assert_equal('file://a/trunk/l10n-kf5/', l.vcs.repository)
  end

  def test_0_repo_url_init_stable
    l = create_stable
    assert_equal(ReleaseMe::TranslationUnit::STABLE, l.type)
    l.init_repo_url('file://a')
    assert_equal(l.vcs.repository, 'file://a/branches/stable/l10n-kf5/')
  end

  # LTS translations should be used but only for Plasma repos
  def test_0_repo_url_init_lts
    assert_raise do
      create_lts
    end
  end

  def test_0_repo_url_init_lts_plasma
    l = create_lts_plasma
    assert_equal(ReleaseMe::TranslationUnit::LTS, l.type)
    l.init_repo_url('file://a')
    assert_equal(l.vcs.repository, 'file://a/branches/stable/l10n-kf5-plasma-lts/')
  end

  def test_invalid_inits
    assert_raise do
      ReleaseMe::TranslationUnit.new(nil, 'amarok', '/dev/null')
    end
    assert_raise do
      ReleaseMe::TranslationUnit.new(ReleaseMe::TranslationUnit::TRUNK, nil, 'null')
    end
    assert_raise do
      ReleaseMe::TranslationUnit.new(ReleaseMe::TranslationUnit::TRUNK, 'amarok', nil)
    end
  end

  def test_invalid_type
    assert_raise do
      # :fishyfishy is a bad type and can't be mapped to a repo path
      ReleaseMe::TranslationUnit.new(:fishyfishy, 'amarok', '/dev/null')
    end
  end

  def test_simple_kde4
    # Technically we could handle kde4, given this is a fairly low level class
    # we may just get away with this.
    u = ReleaseMe::TranslationUnit.new(ReleaseMe::Origin::TRUNK_KDE4, 'amarok',
                                       '/dev/null')
    assert_equal('svn://anonsvn.kde.org/home/kde//trunk/l10n-kde4/',
                 u.vcs.repository)
  end

  def test_default_exclusion
    u = create_trunk
    langs = u.languages
    assert_not_include(langs, 'x-test')
    assert_false(langs.empty?)
  end

  def test_exclusion
    u = create_trunk
    u.default_excluded_languages = []
    assert_include(u.languages, 'x-test')
    # Make sure the exclusion list is not cached so it can be changed later.
    u.default_excluded_languages = nil
    assert_not_include(u.languages, 'x-test')
  end
end
