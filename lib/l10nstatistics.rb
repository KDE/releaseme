class L10nStatistics
    attr_reader :stats

    def initialize()#project)
#         @project = project
        @stats = {}
    end

    def gather!(sourceDirectory)
        poDir = "#{sourceDirectory}/po/"
        Dir.chdir(poDir) do
            languages = Dir.glob("*")
            languages.each do |language|
                next unless File.directory?(language)
                Dir.chdir(language) do
                    values = nil

                    translated = 0
                    fuzzy = 0
                    untranslated = 0

                    for file in Dir.glob("*.po")
                        data = %x[LC_ALL=C LANG=C msgfmt --statistics #{file} > /dev/stdout 2>&1]

                        # tear the data apart and create some variables
                        data.split(",").each do |x|
                            if x.include? "untranslated"
                                untranslated += x.scan(/[\d]+/)[0].to_i
                            elsif x.include? "fuzzy"
                                fuzzy += x.scan(/[\d]+/)[0].to_i
                            elsif x.include? "translated"
                                translated += x.scan(/[\d]+/)[0].to_i
                            end
                        end
                    end

                    all = translated + fuzzy + untranslated
                    notshown = fuzzy + untranslated
                    shown = all - notshown
                    percentage= ((100.0 * shown.to_f) / all.to_f)

                    @stats[language] = {
                        :all => all,
                        :shown => shown,
                        :notshown => notshown,
                        :percentage => percentage
                    }
                    p @stats
                end
            end
        end
    end

    def write(html_file_path)
    end
end