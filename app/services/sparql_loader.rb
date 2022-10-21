# Class to load SPARQL from local or remote files
class SparqlLoader
 
  def self.load(filename, substitute_list = [])
    f = File.read("app/services/sparqls/#{filename}.sparql")
    substitute_list.each_slice(2) do |a, b|
      f.gsub!(a.to_s, b.to_s)
    end
    f
  end

  def self.load_url(url,  substitute_list = [] )
    begin
      result = HTTParty.get(url)
    rescue => exception
      return { error: exception.message }
    end
    result = HTTParty.get(url)
    if result.code == 200
      f = result.body
      substitute_list.each_slice(2) do |a, b|
        f.gsub!(a.to_s, b.to_s)
      end
    else
      { error: result.code, message: result.body.truncate(100).squish }
    end
  end
end