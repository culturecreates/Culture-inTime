# Class to load SPARQL from local files
class SparqlLoader
 
  def self.load(filename, substitute_list = [])
    f = File.read("app/services/sparqls/#{filename}.sparql")
    substitute_list.each_slice(2) do |a, b|
      f.gsub!(a.to_s, b.to_s)
    end
    f
  end

  def self.load_url(url, str_to_replace = '', value = '' )
    begin
      result = HTTParty.get(url)
    rescue => exception
      return { error: exception.message }
    end
    result = HTTParty.get(url)
    if result.code == 200
      result.body.gsub(str_to_replace, value)
    else
      { error: result.code, message: result.body.truncate(100).squish }
    end
  end
end