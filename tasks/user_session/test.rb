require '../../lib/log_collector.rb'
require 'date'

TMP_PATH = "../../tmp/userSession"

site_name = "haru-au"
last_date = "2016-03-15"

c = LogCollector.new([site_name], "2016-01-01", last_date, TMP_PATH, ENV["WWWUSER_PASSWD"])
c.set_collect_carriers({'aupass' => 70})
#c.set_grep_key('campaign/download')
c.set_grep_key('/pay/|already')
#c.set_grep_key('/top/')
#c.set_grep_key('/pay/sleep/index')

#c.collect
#PP.pp(c.get_dau)
#printf(c.get_user_session_count)

=begin
count = c.get_user_session_count
File.open(site_name + ".csv", "w") {|file|
  count.each_line{|line|
    file.puts line
  }
}
=end

users = c.get_user_session_ua
File.open(site_name + "_UA" + ".csv", "w") {|file|
  users.each{|site, site_data|
    site_data.each{|carrier, carrier_uids|
      carrier_uids[Date.parse(last_date).strftime("%Y/%m/%d")].each {|text|
        text = text.gsub(/--split--/, ",")
        file.puts text
      }
    }
  }
}

#printf c.get_dau_count
