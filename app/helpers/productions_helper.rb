module ProductionsHelper

  require 'digest/md5'

  def production_image(production)
    if production&.main_image.blank?
      if production&.title
        color = Digest::MD5.hexdigest(production&.title)[0..5]
      else
        color = Digest::MD5.hexdigest("missing-title")[0..5]
      end
      "https://dummyimage.com/300x200/#{color}/ffffff.png&text=#{production.title}"
    else
      # Convert wikimedia urls to https to fix image rendering problem. see https://github.com/culturecreates/Culture-inTime/issues/9
      url = if production.main_image.class == String
        production.main_image
      else
        production.main_image.value
      end
      url.gsub("http://commons.wikimedia.org/wiki/Special:","https://commons.wikimedia.org/wiki/Special:")
    end
  end

  def date_display(date_time)
    begin
      I18n.l(Date.parse(date_time), format: :long)
    rescue
      "-"
    end
   
  end

  def date_time_display(date_time)
    Time.zone = 'Eastern Time (US & Canada)'
    I18n.l(date_time.in_time_zone, format: :long)
  end
end
