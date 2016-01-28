require '../../lib/log_collector.rb'

TMP_PATH = "../../tmp/userSession"

c = LogCollector.new(["karin-pack"], "2016-01-07", "2016-01-25", TMP_PATH, ENV["WWWUSER_PASSWD"])
c.set_collect_carriers({'aupass' => 70})
c.set_grep_key('campaign/download')
#c.collect
#PP.pp(c.get_dau)
PP.pp(c.get_user_session)
#printf c.get_dau_count
#c.cleanup
