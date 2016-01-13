require 'date'
require 'fileutils'
require 'pty'
require 'expect'
require 'pp'

class LogCollector
  CARRIERS = {'docomo' => 1, 'au' => 2, 'softbank' => 3, 'sp_docomo' => 6, 'sp_au' => 7, 'sp_softbank' => 9}
  SERVERS = ["nwsa-01", "nwsa-02", "nwsa-04", "nwsb-01", "nwsb-02", "nwsb-03", "nwsb-04", "nwsb-05", "nwsb-06"]
  GREP_KEY = "/pay/"

  @sites
  @begin_date
  @end_date

  @collect_carriers
  @tmp_path
  @ssh_passwd

  def initialize(sites, begin_date, end_date, tmp_path, ssh_passwd)
    @sites = sites

    if begin_date == nil
      @begin_date = Date.today
    else
      @begin_date = Date.parse(begin_date)
    end

    if end_date == nil
      @end_date = Date.today
    else
      @end_date = Date.parse(end_date)
    end

    @collect_carriers = "all"
    @tmp_path = tmp_path
    @ssh_passwd = ssh_passwd
  end

  def validate()
    if !@sites.is_a? Array
      return false
    end

    if !@begin_date.is_a? Date
      return false
    end
    if !@end_date.is_a? Date
      return false
    end

    return true
  end

  def set_collect_carriers(carriers)
    @collect_carriers = carriers
  end

  def make_tmp_file_path(file_name, date)
    "#{file_name}.#{date.strftime("%Y%m%d")}.gz"
  end

  def make_file_path_at_month(site, file_name, date)
    "/home/#{site}/logs/#{date.year}/#{"%02d" % date.month}/#{file_name}.*.gz"
  end

  def make_file_path(site, file_name, date)
    "/home/#{site}/logs/#{date.year}/#{"%02d" % date.month}/#{file_name}.#{date.strftime("%Y%m%d")}.gz"
  end

  def pty(cmd)
    PTY.getpty(cmd) do |i,o|
      o.sync = true
      i.expect(/password:/,10){ |line|
        puts line
        o.puts @ssh_passwd
        o.flush
      }
      while( i.eof? == false )
        puts i.gets
      end
    end
  end

  def collect
    if !Dir.exist? @tmp_path
      Dir.mkdir @tmp_path, 0755
    end

    SERVERS.each {|server|
      tmp_path = "#{@tmp_path}/#{server}"
      if !Dir.exist? tmp_path
        Dir.mkdir tmp_path, 0755
      end

      @sites.each { |site|
        tmp_path = "#{@tmp_path}/#{server}/#{site}"
        if !Dir.exist? tmp_path
          Dir.mkdir tmp_path, 0755
        end

        month = -1
        (@begin_date..@end_date).each {|date|
          if date.month != month
            file_path = make_file_path_at_month(site, "*.userSession.log", date)
            cmd = "scp wwwuser@#{server}:#{file_path} #{tmp_path}/"
            #puts cmd
            self.pty cmd

            month = date.month
          end
        }
      }
    }
  end

  def cleanup
    FileUtils.rm_r(Dir.glob("#{@tmp_path}/*"))
  end

  def set_collect_carriers
    if @collect_carriers == "all"
      return CARRIERS
    end

    return @collect_carriers
  end

  # UIDユニーク(日別)
  def get_dau
    carriers = self.set_collect_carriers
    results = {}

    @sites.each { |site|
      results[site] = {}
      (@begin_date..@end_date).each {|target_date|
        carrier_results = {}
        carriers.each{|carrier, carrier_id|
          uids = []
          SERVERS.each {|server|
            file_path = self.make_tmp_file_path("#{carrier_id}.userSession.log", target_date)
            file_path = "#{@tmp_path}/#{server}/#{site}/#{file_path}"
            if File.exist? file_path
              cmd = "gzcat #{file_path} | egrep \"#{GREP_KEY}\""
              data = `#{cmd}`
              data.lines{|line|
                # http://blog.livedoor.jp/sonots/archives/34702351.html
                uids << line.scrub("!").split(' ')[4]
              }
            end
          }

          carrier_results[carrier] = uids.uniq
        }
        results[site][target_date.strftime("%Y/%m/%d")] = carrier_results
      }
    }
    #PP.pp(results)
    return results
  end

  # UIDユニーク数(日別)
  def get_dau_count
    results = self.get_dau

    return_str = ""
    output_date_format = "|\\2. %s|\n"
    output_carrier_format = "|=. %s|>. %d|\n"

    results.each{|site, site_data|
      return_str += "\n\n---------- #{site} ----------\n"
      site_data.each {|date, carrier_uids|
        return_str += sprintf(output_date_format, date)
        carrier_uids.each { |carrier, uids|
          return_str += sprintf(output_carrier_format, carrier, uids.size)
        }
      }
    }

    return return_str
  end

  # UIDユニーク(指定期間)
  def get_user_session
    carriers = self.set_collect_carriers
    results = {}

    @sites.each { |site|
      results[site] = {}
      carrier_results = {}

      carriers.each{|carrier, carrier_id|
        uids = []
        (@begin_date..@end_date).each {|target_date|
          SERVERS.each {|server|
            file_path = self.make_tmp_file_path("#{carrier_id}.userSession.log", target_date)
            file_path = "#{@tmp_path}/#{server}/#{site}/#{file_path}"
            if File.exist? file_path
              cmd = "gzcat #{file_path} | egrep \"#{GREP_KEY}\""
              data = `#{cmd}`
              data.lines{|line|
                # http://blog.livedoor.jp/sonots/archives/34702351.html
                uids << line.scrub("!").split(' ')[4]
              }
            end
          }
        }
        carrier_results[carrier] = uids.uniq
      }
      results[site] = carrier_results
    }
    return results
  end

  # UIDユニーク数(指定期間)
  def get_user_session_count
    results = self.get_user_session

    return_str = ""
    output_carrier_format = "|=. %s|>. %d|\n"

    results.each{|site, site_data|
      return_str += "\n\n---------- #{site} ----------\n"
      site_data.each {|carrier, carrier_uids|
        return_str += sprintf(output_carrier_format, carrier, carrier_uids.size)
      }
    }
    return return_str
  end
end
