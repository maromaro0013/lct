require '../../lib/log_collector.rb'

TMP_PATH = "../../tmp/userSession"

site_name = "beppu"

c = LogCollector.new([site_name], "2016-02-01", "2016-02-29", TMP_PATH, ENV["WWWUSER_PASSWD"])
#c.set_collect_carriers({'aupass' => 70})
#c.set_grep_key('campaign/download')
#c.set_grep_key('/pay/|already')
#c.set_grep_key('/top/')
c.set_grep_key('/pay/sleep/index')

#c.collect
#PP.pp(c.get_dau)
#printf(c.get_user_session_count)
count = c.get_dau_count
File.open(site_name + ".csv", "w") {|file|
  count.each_line{|line|
    file.puts line
  }
}

#printf c.get_dau_count
