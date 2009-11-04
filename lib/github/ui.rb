require "readline"
require "highline"
module GitHub
  module UI
    extend self
    # Take a list of items, including optional ' # some description' on each and
    # return the selected item (without the description)
    def display_select_list(list)
      HighLine.track_eof = false
      long_result = HighLine.new.choose do |menu|
        list.each { |item| menu.choice item }
        menu.header = "Select a repository to clone"
      end
      long_result && long_result.gsub(/\s+#.*$/,'')
    end
  end
end