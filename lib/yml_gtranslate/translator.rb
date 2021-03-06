require 'json'
require 'uri'
require 'ya2yaml'
require 'yaml'

# irb -I/path_to_your/yml_gtranslate/lib
# require 'byebug'
# (load 'yml_gtranslate.rb') && YmlGtranslate::Translator.new("pt","en",'/path_to_your/config/locales/devise.pt.yml').translate_locales
# gem build yml_gtranslate.gemspec && gem install yml_gtranslate-0.0.5.gem

module YmlGtranslate
  class Translator
    def initialize(from_lang, to_lang, dir)
      @from_lang = from_lang
      @to_lang = to_lang
      @directory_or_file = dir || "**"
    end
    
    COMMENT_TOKEN = "" # "#i18n-GT"
    
    def translate(string)
      if string == '' || string == nil
        return ''
      end
      if string.is_a? Symbol
        puts "ruby symbol #{string}"
        return string
      end
      string = string.dup # we need this since some strings could be chared between keys since yml use <<: reference
      original_string = string.dup
      temp_matches = {}
      # replace html tags <label> with random string, before replacing #{} since they could be inside html tags
      string.scan(/<.*?>/).each do |m|
        temp_matches[m] = Random.rand.to_s[2..-1]
        string.sub!(m,temp_matches[m])
      end
      # replace #{something} or %{blabla} %H with random string
      # [%#] start with % or #
      # non capturing group and or statement (?: | )
      # \{.*?\}  start and end with {} and use least match ? 
      # \w+ match word
      string.scan(/[%#](?:\{.*?\}|\w+)/).each do |m|
        temp_matches[m] = Random.rand.to_s[2..-1]
        string.sub!(m,temp_matches[m])
      end
      command = <<-EOF
      curl -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:5.0) Gecko/20100101 Firefox/5.0" "http://translate.google.com/translate_a/t?client=t&text=#{URI.escape(string)}&hl=#{@from_lang}&sl=auto&tl=#{@to_lang}&multires=1&prev=conf&psl=auto&ptl=#{@from_lang}&otf=1&it=sel.7123%2Ctgtd.3099&ssel=0&tsel=4&uptl=#{@to_lang}&sc=1"
      EOF
      command.strip!
      output = `#{command}`
      # [,,,"pt"]  should be ["pt"]
      res = output.gsub(/,+/, ",").gsub(/\[,/,"[")
      translated_string = JSON.parse(res).first.first.first.strip
      temp_matches.each do |m,v|
        translated_string.gsub!(v,m)
      end
      puts "#{original_string} -> #{translated_string}"
      translated_string
    rescue
      puts "!!! Can't translate '#{original_string.class}' output=#{output}"
      "bad_translation"
    end
    
    def comment(string)
      string + COMMENT_TOKEN
    end


    def compare(hash1, hash2, target_key)
      # iterate over input hash
     hash1.inject({}) do |h, pair|
       key, value = pair
       if hash2.key?(key)
         # output has that key so we will use that it is the same type
         if value.is_a? Hash
           if hash2[key].is_a? Hash
             # recursive call translate when output is also a Hash)
             h[key] = compare(value, hash2[key], target_key+"#{key}.")
           else
             puts "!!!! #{target_key}#{key} existing translation (#{hash2[key]}) should be an object. Ignoring it... !!!!!"
             h[key] = compare(value, {}, target_key+"#{key}.")
           end
         elsif value.is_a?(Array)
           if hash2[key].is_a?(Array) && value.length == hash2[key].length
             # it is the same type and length
             h[key] = hash2[key]
           else
             # differs in lenght or type, ignoring
             puts "!!!! #{target_key}#{key} existing translation (#{hash2[key]}) is not array with same size. Ignoring it... !!!!!"
             h[key] = value.map { |i| comment(translate(i))} 
           end
         else
           # its is simple type so use that
           #puts "#{target_key}#{key} use existing value: #{value} -> #{hash2[key]}"
           h[key] = hash2[key]
         end
       else
         # output does not have that key
         if value.is_a?(Hash) 
           h[key] = compare(value, {}, target_key+"#{key}.")
         elsif value.is_a?(String)
           # translate recursive calls stops here
           printf "#{target_key}#{key}: "
           h[key] =  comment(translate(value))
         elsif value.is_a?(TrueClass) ||
           value.is_a?(Fixnum) ||
           value.is_a?(Float) ||
           value.is_a?(FalseClass) ||
           value.is_a?(NilClass)
           # here is true, false, number
           puts "#{target_key}#{key} is simple type: #{value} -> #{value}"
           h[key] =  value  
         elsif value.is_a?(Array)
           puts "#{target_key}#{key} is array:"
           h[key] = value.map { |i| translate(i)} 
         else
           puts "================== !!! Unknown class #{value} #{value.class} !!!"
           h[key] = value
           break
         end
       end
       h
     end
    end
    
    
  
  
  def translate_locales
    if File.file? @directory_or_file
      files = [@directory_or_file]
      puts "Use that file"
    else
      files = Dir.glob(File.join(@directory_or_file, "*#{@from_lang}.yml"))
      puts "Found #{files.length} files"
    end

    files.each do |f|
      printf "\nprocessing #{f} "
      prefix = f.split("#{@from_lang}.yml").first.to_s
      to_file =  "#{prefix}#{@to_lang}.yml"
      begin
        from_hash = YAML.load_file(f)[@from_lang.to_s]
      rescue Exception => e
        puts "=============== !!! Error in processing YML !!!"
        puts "Skipping malformed yml file in #{f} #{e}"
        next
      end
    
      to_hash = {}
      if File.exists?(to_file)
        puts "and use existing #{@to_lang}.yml file"
        incomment = "sed s/\\\"\\ #i18n-GT/#i18n-GT\\\"/g #{to_file} > tmp.yml; rm #{to_file}; mv tmp.yml #{to_file}"
        #`#{incomment}`
        to_hash = YAML.load_file(to_file)[@to_lang.to_s] || {}
      else
        puts "creating new file #{to_file}"
      end

      result = compare(from_hash, to_hash, "#{f.rpartition('/').last}:")

      File.open("#{to_file}", 'w') do |out|
        out.write({@to_lang.to_s => result}.to_yaml)
      end

      comment = "sed s/#i18n-GT\\\"/\\\"\\ #i18n-GT/g #{to_file} > tmp.yml; rm #{to_file}; mv tmp.yml #{to_file}"
    
      #`#{comment}`
    end
  end


  end
end
