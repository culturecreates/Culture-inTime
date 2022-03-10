module ProductionsHelper

  require 'digest/md5'

  def production_image(production)
    if production&.main_image&.blank?
      color = Digest::MD5.hexdigest(production.title)[0..5]
      "https://dummyimage.com/300x200/#{color}/ffffff.png&text=#{production.title}"
    else
      production&.main_image
    end
  end

  def date_display(date_time)
    begin
      I18n.l(Date.parse(date_time), format: :long)
    rescue
      "no date"
    end
   
  end

  def date_time_display(date_time)
    Time.zone = 'Eastern Time (US & Canada)'
    #I18n.l(date_time, format: :long)
    date_time.in_time_zone.strftime("%d %b %Y - %a - %H:%M %Z")
  end
end
