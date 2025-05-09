require 'net/smtp'

module MmMail
  # General exception class when something goes wrong in MmMail
  class TransportError < Exception; end
  
  # Handles the transportation of a {Message} to its destination.
  # Basic support for SMTP (through +Net::SMTP+) or +sendmail+.
  # 
  # You can either pass a new {Transport::Config} object during transport or use 
  # the system wide {Transport::DefaultConfig} object. 
  # 
  # @example [To set transport to use sendmail]
  #   MmMail::Transport::DefaultConfig.method = :sendmail
  #   # Note you might need to point to sendmail if it's not in your PATH:
  #   MmMail::Transport::DefaultConfig.sendmail_binary = '/path/to/sendmail'
  # 
  # @example [To connect to your ISP SMTP server on 587]
  #   MmMail::Transport::DefaultConfig.host = 'smtp.myisp.com'
  #   MmMail::Transport::DefaultConfig.port = 587
  # 
  # @see Transport::Config
  # @see Transport::mail
  class Transport
    # Configuration class for a {Transport}
    class Config
      # Set/get the SMTP host/port information
      attr_accessor :host, :port
      
      # Set/get the authentication type (nil for none, :plain, :login or :cram_md5)
      attr_accessor :auth_type
      
      # Set/get the AUTH user/password when using SMTP transport.
      attr_accessor :auth_user, :auth_pass
      
      # Set/get the email method. Allowed values are +:smtp+ or +:sendmail+.
      attr_accessor :method
      
      # Set/get the location of the sendmail binary on the system
      attr_accessor :sendmail_binary

      # Creates a new Config object set to send via SMTP on
      # localhost:25 with no authentication.
      def initialize
        @method = :smtp # :sendmail
        @host = 'localhost'
        @port = 25
        @auth_type = nil # :plain, :login, :cram_md5
        @auth_user = nil
        @auth_pass = nil
        @sendmail_binary = 'sendmail'
      end
    end
    
    # The default system wide configuration used when no custom config
    # object is provided to a Transport object. If you want to make global
    # configuration changes, change the settings here.
    DefaultConfig = Config.new

    # Creates a new {Transport} object and sends an email.
    # 
    # @see #mail
    def self.mail(message, config = nil)
      new(config).mail(message)
    end
    
    # Sets a {Config} object to use when sending mail
    attr_accessor :config
    
    # Creates a new Transport object to send emails with. To change
    # settings to sendmail or use SMTP auth, set these in the {Config}
    # object.
    #  
    # @param [Config] a configuration to use
    # @raise [ArgumentError] if config is not a {Config} object.
    def initialize(config = nil)
      if config && !config.is_a?(Config)
        raise ArgumentError, "expected #{self.class}::Config"
      end
      
      @config = config || DefaultConfig
    end
    
    # Sends a {Message} object out as an email using the configuration
    # set during initialization.
    # 
    # @param [Message] message an email to send
    # @raise [ArgumentError] if message is not a {Message} object
    # @raise [TransportError] if message is not {Message#valid? valid}.
    def mail(message)
      unless Message === message
        raise ArgumentError, "expected MmMail::Message, got #{message.class}"
      end
      
      raise TransportError, "invalid message" unless message.valid?
      
      send("mail_#{config.method}", message)
    end
    
    # Sends a mail through Net::SMTP using the {#config} if
    # any SMTP or hostname information is set.
    # 
    # @param [#to_s] message the message to send
    def mail_smtp(message)
      Net::SMTP.start(config.host, config.port, 'localhost.localdomain', 
          config.auth_user, config.auth_pass, config.auth_type) do |smtp|
        smtp.send_message(message.to_s, message.from, message.recipients_list)
      end
    end
    
    # Sends a mail through sendmail using the {Config#sendmail_binary} as the
    # location of the file.
    # 
    # @param [#to_s] message the message to send
    # @raise [TransportError] if a problem during execution occured
    def mail_sendmail(message)
      bin, err = config.sendmail_binary, ''
      result = IO.popen("#{bin} -t 2>&1", "w+") do |io|
        io.write(message.to_s)
        io.close_write
        err = io.read.chomp
      end
      
      raise TransportError, err if $? != 0
    end
  end

  # A Message object representing an Email to be passed to a {Transport}.
  class Message
    # Creates a new message with associated fields.
    # 
    # @example
    #   MmMail::Message.new(:to => 'test@example.com', :body => 'hi')
    # 
    # @param [Hash] opts the options to create a message with.
    # @option opts [String] :from ('nobody@localhost') The email's From field
    # @option opts [String] :subject ('') The email's Subject field
    # @option opts [String] :body ('') The email's body (not a header)
    # @option opts [String] :to (nil) The email's To field. List multiple recipients as
    #   'a@b.c, b@c.d', not an array.
    def initialize(opts = {})
      defaults = {
        :from => 'nobody@localhost',
        :subject => '',
        :body => ''
      }
      @headers = defaults.merge(opts)
    end
    
    # Allow access of fields by header name or symbolic representation
    # 
    # @example
    #   m[:x_message_id] = '1234'
    #   m['X-Message-Id'] == '1234' # => true
    # 
    # @param [String, Symbol] k the header or symbolic header value to lookup.
    # @return [String] the value associated with the field
    def [](k)     @headers[translate_header_to_sym(k)]     end

    # Allow access of fields by header name or symbolic representation
    # 
    # @example
    #   m[:x_message_id] = '1234'
    #   m['X-Message-Id'] == '1234' # => true
    # 
    def []=(k, v) @headers[translate_header_to_sym(k)] = v end
    
    # Override this method to allow any call to obj.meth or obj.meth= to
    # set a header field on this object.
    # 
    # @example [To set the field 'X-Message-Id']
    #   m.x_message_id = '1234'
    #   m.x_message_id == '1234' # => true
    # 
    def method_missing(sym, *args)
      if sym.to_s =~ /=$/
        self[sym.to_s[0..-2].to_sym] = args.first
      elsif @headers.has_key?(sym)
        self[sym]
      else
        super
      end
    end
    
    # Override this method to verify if a field has been set.
    # 
    # @return [Boolean] whether the field was set (or if a regular method
    #   is callable.)
    def respond_to?(sym)
      return true if super
      @headers.has_key?(sym)
    end
    
    # Returns the message in its full form as expected by an SMTP server.
    # 
    # @return [String] the email with headers followed by a body
    def to_s
      [headers, body].join("\n")
    end
    
    # Returns all the recipients in the To field.
    # 
    # @example
    #   m.to = 'a@b.c, b@c.d'
    #   m.recipients_list # => ['a@b.c', 'b@c.d']
    # 
    # @return [Array<String>] the emails in the To field of the message.
    def recipients_list
      to.split(/\s*,\s*/)
    end
    
    # Checks if the message is valid. Validity is based on
    # having the From, To and Subject fields set. From and To
    # must not be empty.
    # 
    # @return [Boolean] whether or not the message is a valid e-mail
    def valid?
      [:from, :to].each do |field|
        return false if !self[field] || self[field].empty?
      end
      
      self[:subject] ? true : false
    end
    
    private
    
    # Returns the headers as the RFC822 string.
    # 
    # @return [String] the headers in RFC822 format
    def headers
      @headers.reject {|k, v| k == :body }.map do |k, v|
        translate_header_name(k) + ': ' + v + "\n"
      end.join
    end

    # Translates a header from its symbolic representation to its
    # RFC822 header name or the other way around. If you give in
    # a header name (String) you will get a Symbol, and a Symbol
    # if you give a String.
    # 
    # @example
    #   msg.translate_header_name(:x_message_id) # => 'X-Message-Id'
    #   msg.translate_header_name('Content-Type') # => :content_type
    # 
    # @param [String,Symbol] key the header name to translate
    # @return [Symbol,String] the symbolic or header representation of
    #   the symbol or header name.
    # @raise [ArgumentError] if key is neither a String or Symbol
    def translate_header_name(key)
      case key
      when String
        key.downcase.tr('-', '_').to_sym
      when Symbol
        key.to_s.capitalize.gsub(/_(.)/) {|m| '-' + m[1].upcase }
      else
        raise ArgumentError, "invalid key type #{key.class}"
      end
    end
    
    # Translates a header one-way to the symbolic representation.
    # 
    # @param [String, Symbol] key any header or symbolic key
    # @return [Symbol] the symbolic representation of the header name
    # @see #translate_header_name
    def translate_header_to_sym(key)
      return key if Symbol === key
      translate_header_name(key)
    end
  end
  
  # Quickly send out an email.
  # 
  # @example
  #   MmMail.mail(:to => 'me@gmail.com', :body => 'hi!')
  # 
  # @param [Hash] opts the hash used to construct the message
  # @param [Transport::Config, nil] config the configuration object to use
  #   during transport
  # @see Transport#mail
  def self.mail(opts = {}, config = nil)
    Transport.mail(Message.new(opts), config)
  end
end