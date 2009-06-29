#!ruby -Ku
#-*- coding: utf-8 -*-
require 'sixamo'
require 'oauth' # :nodoc: before do gem install --remote oauth
require 'oauth/signature/rsa/sha1'
require 'oauth/request_proxy/rack_request'

class SixamoJson
  # mixi.jpコンテナの公開鍵 動的更新ではなくリテラルベタ貼り
  MIXI_CERTIFICATE = <<-EOF
-----BEGIN CERTIFICATE-----
MIICdzCCAeCgAwIBAgIJAOi/chE0MhufMA0GCSqGSIb3DQEBBQUAMDIxCzAJBgNV
BAYTAkpQMREwDwYDVQQKEwhtaXhpIEluYzEQMA4GA1UEAxMHbWl4aS5qcDAeFw0w
OTA0MjgwNzAyMTVaFw0xMDA0MjgwNzAyMTVaMDIxCzAJBgNVBAYTAkpQMREwDwYD
VQQKEwhtaXhpIEluYzEQMA4GA1UEAxMHbWl4aS5qcDCBnzANBgkqhkiG9w0BAQEF
AAOBjQAwgYkCgYEAwEj53VlQcv1WHvfWlTP+T1lXUg91W+bgJSuHAD89PdVf9Ujn
i92EkbjqaLDzA43+U5ULlK/05jROnGwFBVdISxULgevSpiTfgbfCcKbRW7hXrTSm
jFREp7YOvflT3rr7qqNvjm+3XE157zcU33SXMIGvX1uQH/Y4fNpEE1pmX+UCAwEA
AaOBlDCBkTAdBgNVHQ4EFgQUn2ewbtnBTjv6CpeT37jrBNF/h6gwYgYDVR0jBFsw
WYAUn2ewbtnBTjv6CpeT37jrBNF/h6ihNqQ0MDIxCzAJBgNVBAYTAkpQMREwDwYD
VQQKEwhtaXhpIEluYzEQMA4GA1UEAxMHbWl4aS5qcIIJAOi/chE0MhufMAwGA1Ud
EwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAR7v8eaCaiB5xFVf9k9jOYPjCSQIJ
58nLY869OeNXWWIQ17Tkprcf8ipxsoHj0Z7hJl/nVkSWgGj/bJLTVT9DrcEd6gLa
h5TbGftATZCAJ8QJa3X2omCdB29qqyjz4F6QyTi930qekawPBLlWXuiP3oRNbiow
nOLWEi16qH9WuBs=
-----END CERTIFICATE-----
  EOF

  # 人工無脳ししゃもをクラス変数に確保
  def initialize(dict = @@dict)
    @@dict = dict
    @@core = Sixamo.new(dict)
  end

  # :nodoc:
  class RequestError < StandardError; end

  # mixiコンテナからのアクセスですか？ true or false
  def mixi_signed_request?(env)
    req = OAuth::RequestProxy::RackRequest.new(Rack::Request.new(env))
	if req.oauth_signature_method == 'RSA-SHA1' &&
       req.oauth_consumer_key == 'mixi.jp' &&
	   # TODO: これらの値もチェックする
       # req.xoauth_signature_publickey == 'mixi.jp' &&
       # req.opensocial_app_id == '2938' then
	   consumer = OAuth::Consumer.new(nil, MIXI_CERTIFICATE, {:signature_method => 'RSA-SHA1'})
	   signature = OAuth::Signature.build(req) do
         [nil, consumer.secret]
       end
       if signature.verify
         return true
       end
    end
    return false
  end
  private :mixi_signed_request?

  # 人工無脳ししゃものJSON API, mixiコンテナからのアクセスのみ許容
  class API < SixamoJson
    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      case
        when !req.get?
          raise RequestError.new("Request::Method is not GET")
		when !mixi_signed_request?(env)
		  [ 401, {'Content-Type' => 'text/plain', 'Content-Length' => '13'}, ['Unauthorized.'] ]
      end
      input = req.params['text'] 
      body = '{ "text" : "'+@@core.talk(input)+'" }'
      res.length = body.respond_to?(:bytesize) ? body.bytesize : body.size
      res.instance_variable_set :@header, {"Content-Type"=>"text/javascript+json; charset=utf-8"}
      res.write body
      res.finish
    end
  end
end

