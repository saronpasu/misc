class Net::IRC::Client
  alias_method :orig_post, :post
  private
  def post(command, *params)
    m = Message.new(nil, command, params.map{|s|
      if RUBY_VERSION.match(/1\.9/) && s.encoding.dummy? then
        internal ||= Encoding.default_internal || Encoding::UTF_8
        s ? s.encode(internal).gsub(Regexp.compile("[\\r\\n]".encode(internal)), " ".encode(internal)).encode(s.encoding) : ""
      else
        s ? s.gsub(/[\r\n]/, " ") : ""
      end
    })

    @log.debug "SEND: #{m.to_s.chomp}"
    @socket << m
  end
end

class Net::IRC::Message
  alias_method :orig_to_s, :to_s
  def to_s

    str = ""

    str << ":#{@prefix}" unless @prefix.empty?

    str << @command

    internal ||= Encoding.default_internal || Encoding::UTF_8 if RUBY_VERSION.match(/1\.9/)
    if @params
      f = false
      @params.each do |param|
        str << " "
        if !f && (
          param.size == 0 ||

          RUBY_VERSION.match(/1\.9/) && param.encoding.dummy? ?
            / / =~ param.encode(internal) : / / =~ param ||

          RUBY_VERSION.match(/1\.9/) && param.encoding.dummy? ?
            /^:/ =~ param.encode(internal) : /^:/ =~ param
        )
          str << ":#{param}"
          f = true
        else
          RUBY_VERSION.match(/1\.9/) ? str << param.encode(str.encoding) : str << param
        end
      end

      str << "\x0D\x0A"

      str

    end
  end
end

