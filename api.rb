require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'
require 'logger'
require 'digest/md5'
require 'yaml'
require 'base64'
require 'logger'
require 'cgi'

require "#{File.dirname(__FILE__)}/virtual_api"

dir_path = File.dirname(__FILE__)

@@settings = YAML.load_file("#{dir_path}/settings.yml")

#Logger.new(STDOUT)
#　logger = Logger.new('foo.log', 10, 1024000) #保留10个日志文件，每个文件大小1024000字节
@@logger = Logger.new("#{dir_path}/logs/sinatra_api.log", 'daily') #按天生成
@@logger.level = Logger::INFO #fatal、error、warn、info、debug
# logger.formatter = proc { |severity, datetime, progname, msg|
#   "#{datetime}: #{msg}\n"
# }
#logger.info 'asdfasd'


cert = OpenSSL::X509::Certificate.new File.read File.join(File.dirname(__FILE__), 'certs', 'server.crt')
pkey = OpenSSL::PKey::RSA.new(
    File.open( File.join(File.dirname(__FILE__), 'certs', 'server.key')).read)

log_file = File.open "#{dir_path}/logs/webrick.log",'a+'
webrick_options = {
    :Port               => 3008,
    :ServerType         => WEBrick::SimpleServer, #WEBrick::Daemon or WEBrick::SimpleServer
    #:Logger => WEBrick::Log.new(log_file),
    #:AccessLog => [[log_file,WEBrick::AccessLog::COMBINED_LOG_FORMAT]],
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => cert,
    :SSLPrivateKey      => pkey
}

class MyServer < Sinatra::Base 
 before do
    content_type :json
    #(status,message) = authenticate()
    # if status == 0
    #   result = {status:'failure',
    #       message:message,
    #       command:'authenticate'}
    #
    #s
    #   @@logger.info result.to_json
    #   halt 401, {content_type: 'text/json'}, result.to_json
    # end
  end

    get '/' do
        domain = params[:domain]
        #params.to_json
        #query_str = build_remote_api_url('list_domains',['domain','info'])

        remote_ip = request.env['REMOTE_ADDR']
        #request.env.to_json
        #query_str
        "Hello World!\n"
    end

    get '/test' do
      hash = {username: 'chen', age: 23, email:'c_boxing@hotmail.com',staffs:[{username:'huang',age:25}]}
      hash.to_json
    end


    get '/hosting/show' do
      api_method = 'list-domains'
      arguments = ['domain']
      data_json = call_remote_api(api_method, arguments)
      data_json
    end

    # 参数说明
    # domain 域名 比如seo138.com 或二级域名 w131111.seo138.com
    # user   用户名  不填，系统根据域名自动产生
    # pass   密码    必填
    # template  模板名 ，可选，默认模板
    # plan      帐号计划,可远，默认
    # desc      描述信息,可选
    # email     联系人Email,可选
    # mysql     是否开启mysql
    # ssl       是否启用ssl网站
    # db        数据库名称  可选
    # shared-ip IP地址
    # mysql-pass mysql密码
    post '/hosting/new' do
      api_method = 'create-domain'
      arguments = ['domain',
                   'user',
                   'pass',
                   'desc',                   
                   'template',
                   'plan',
                    'unix',
                    'quota',
                    'uquota',
                    'bandwidth',
                    'dir',
                    'shared-ip',
                    'web']
      data_json = call_remote_api(api_method, arguments)
      data_json
    end
    
    #获取空间绑定域名列表
    get '/hosting/aliases' do
      api_method = 'list-domains'
      arguments = ['user']
      data_json = call_remote_api(api_method, arguments)
      data_json      
    end   
      

    post '/hosting/alias/new' do 
       api_method = 'create-domain'
       arguments = ['domain','parent','alias','template']
       data_json = call_remote_api(api_method, arguments)
       data_json      
    end 
    
    delete '/hosting/alias' do 
      api_method = 'delete-domain'
      arguments = ['domain','only']
      data_json = call_remote_api(api_method, arguments)
      data_json           
    end   

    delete '/hosting/delete' do
      api_method = 'delete-domain'
      arguments = ['domain','user','only']
      data_json = call_remote_api(api_method, arguments)
      data_json
    end

    put '/hosting/enable' do
      api_method = 'enable-domain'
      arguments = ['domain']
      data_json = call_remote_api(api_method, arguments)
      data_json
    end
     
    put '/hosting/disable' do
      api_method = 'disable-domain'				
      arguments = ['domain','why']
      data_json = call_remote_api(api_method, arguments)
      data_json
    end

    put '/hosting/ftp_user_disable' do
      api_method = 'modify-user'
      arguments = ['domain','user','disable']
      data_json = call_remote_api(api_method, arguments)
      data_json	
    end
    
    put '/hosting/ftp_user_enable' do
      api_method = 'modify-user'
      arguments = ['domain','user','enable']
      data_json = call_remote_api(api_method, arguments)
      data_json	
    end
    
    # 修改主机信息
    # domain  查找主机域名
    # new-domain 修改新域名
    # user  新用户名
    # pass  新用户密码
    # quota  空间限额  1024为1M
    # uquota 空间管理员限额  1024为1M
    # bw     30天带宽限制   1024*1024x20 20G
    
    put '/hosting/edit' do 
      api_method = 'modify-domain'
      
      arguments = ['domain','new-domain','user','pass','quota','uquota','bw']
      data_json = call_remote_api(api_method, arguments)
      data_json	
    end   
    
    # 主机网站内容备份
    # dest 服务器所在路径，比如/backup/seo138.com.tar.gz
    # 只备份主机网站内容，只需要设置feature feature=dir
    get '/hosting/backup' do 
      api_method = 'backup-domain'      
      arguments = ['domain','dest','feature']
      data_json = call_remote_api(api_method, arguments)
      data_json	
    end   
    
    # 主机网站内容恢复
    # source 备份好的服务器包
    # feature=dir 只还原网站内容 
    get '/hosting/restore' do 
      api_method = 'restore-domain'      
      arguments = ['domain','source','feature']
      data_json = call_remote_api(api_method, arguments)
      data_json	      
    end   
      
    # 获取空间下的所有数据库，正常来说，应该只有一个数据库    
    get '/hosting/databases' do 
      api_method = 'list-databases'      
      arguments = ['domain']
      data_json = call_remote_api(api_method, arguments)
      data_json	            
    end     
    
    # 删除数据库
    # name 数据库名称
    # type 数据库类型 比如mysql
    delete '/hosting/database/delete' do
      api_method = 'delete-database'      
      arguments = ['domain','name','type']
      data_json = call_remote_api(api_method, arguments)
      data_json	            
    end
    
    # 修改数据库密码
    # type 数据库类型 mysql
    # pass 数据库新密码
    put '/hosting/database/password' do
      api_method = 'modify-database-pass'      
      arguments = ['domain','type','pass']
      data_json = call_remote_api(api_method, arguments)
      data_json	            
    end
    
    # 修改数据库访问用户名
    put '/hosting/database/username' do
      api_method = 'modify-database-user'      
      arguments = ['domain','type','user']
      data_json = call_remote_api(api_method, arguments)
      data_json	            
    end
    
    
    
    delete '/hosting/database/delete' do
      api_method = 'delete-database'      
      arguments = ['domain','name','type']
      data_json = call_remote_api(api_method, arguments)
      data_json	            
    end
   
   post '/hosting/database/new' do
     api_method = 'create-database'      
     arguments = ['domain','name','type']
     data_json = call_remote_api(api_method, arguments)
     data_json
     
   end     
      
    
   

    def call_remote_api(api_method, opts=[])
       api_command = build_remote_api_url(api_method,opts)
       output_json = `#{api_command}`
       #result = $?.success?
       output_json
    end
    
    
    

    #using string key to built md5 string to validate
    def authenticate()
      params_vals = ""
      opts = params.keys || []
      opts.delete "md5"
      opts.sort!
      opts.each do |opt|
        if params.has_key? opt
          val =  params[opt]
          val = "" if val == nil
          params_vals << val
        end
      end

      remote_ip = request.env['REMOTE_ADDR']
      access_ips = @@settings["access_server_ip"]

      key = @@settings['md5_key']
      params_vals << key
      md5_hex = Digest::MD5.hexdigest(params_vals)
      message = ''
      status = 1
      if params['md5'] != md5_hex
         status = 0
         message = 'MD5 string not matched'
         @@logger.info "requested md5: #{params['md5']}, but comptuered md5: #{md5_hex} from #{params_vals}"
      end

      if !access_ips.include?(remote_ip)
         status = 0
         message += "  #{remote_ip} rejected"
      end

      [status, message]

    end

    def build_remote_api_url(api_method,opts=[])
      remote_api_user = @@settings['virtualmin_user']
      remote_api_password = Base64.decode64(@@settings['virtualmin_password'])
      remote_api_ip = @@settings['virtualmin_ip']
      remote_api_port = @@settings['virtualmin_port']
      request_command ="wget -O - --quiet --http-user=#{remote_api_user} --http-passwd=#{remote_api_password} --no-check-certificate \"https://#{remote_api_ip}:#{remote_api_port}/virtual-server/remote.cgi?program=#{api_method}"

      str_opts = '&json=1'
      opts.each do |opt|
        if params.has_key? opt
          # TO-DO if need to encode the string using CGI.escape
          if params[opt] == ""
             str_opts << "&#{opt}"
          else
             str_opts << "&#{opt}=#{CGI.escape(params[opt])}"
          end     
        end
      end
      request_command_query = request_command + str_opts + "\""
      mask_str = request_command_query.gsub(/--http-passwd=(.*) --no-check/,'--http-passwd=****** --no-check')
      @@logger.info mask_str
      request_command_query
    end
 
end

temp_path = File.dirname(__FILE__) + '/temp'
Dir.mkdir temp_path unless Dir.exist?(temp_path)
pfile = "#{temp_path}/webrick.pid"

server = ::Rack::Handler::WEBrick
[:INT, :TERM].each do |sig|
  trap(sig) do
    File.delete(pfile) if File.exist?(pfile)
    server.shutdown
  end
end


pid = Process.pid
server.run(MyServer, webrick_options) do |server|
  File.open(pfile, 'w'){ |f| f.write(pid.to_s) }
end