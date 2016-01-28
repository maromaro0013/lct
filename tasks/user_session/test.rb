require '../../lib/log_collector.rb'

TMP_PATH = "../../tmp/userSession"

c = LogCollector.new(["karin-pack"], "2016-01-01", "2016-01-27", TMP_PATH, ENV["WWWUSER_PASSWD"])
c.set_collect_carriers({'aupass' => 70})
#c.set_grep_key('campaign/download')
c.set_grep_key('/pay/|already')
#c.collect
#PP.pp(c.get_dau)
printf(c.get_user_session_count)
#printf c.get_dau_count
#c.cleanup
