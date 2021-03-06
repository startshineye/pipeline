class Video
  include DataMapper::Resource
  @@new_list = false
  @@validation_url = 'http://gdata.youtube.com/feeds/api/videos/'
  
  property :id, Serial
  property :url, Text, :lazy => false, :format => Proc.new {|str|
    unless str.nil?
      url = @@validation_url + str.gsub(/.*youtube.com\/watch\?v=/, '').gsub(/&.*/, '')
      result = Net::HTTP.get(Module::URI.parse(url))
      if result == 'Invalid id'
        false
      else
        true
      end
    else
      false
    end
    }, :message => "check video url"
  property :title, Text, :lazy => false, :default => "Pending..."
  property :created_at, DateTime
  property :updated_at, DateTime
  property :ip, String
  property :count, Integer, :default => 0
  property :thumbnail, String, :nullable => :false
  
  before :valid? do
    validation_url = @@validation_url + self.url.gsub(/.*youtube.com\/watch\?v=/, '').gsub(/&.*/, '')
    result = Net::HTTP.get(Module::URI.parse(validation_url))
    parser = Hpricot(result)
    thumbnail = (parser/'media:thumbnail')[1]
    title = (parser/'media:title').first
    unless (parser/'yt:noembed').size.zero?
      self.errors.add(:url, "video isn't embeddable")
      throw :halt
    end
    if thumbnail
      self.thumbnail = thumbnail[:url]
    end
    if title
      self.title = title.inner_html
    end
  end
  
  after :save do
    @@new_list = true
  end
  
  def self.list
    self.all :order => [:updated_at.desc]
  end
  
  def self.new_list?
    @@new_list
  end
  
  def next
    Video.first :updated_at.gt => self.updated_at, :order => [:updated_at.asc]
  end
  
  def prev
    Video.first :updated_at.lt => self.updated_at, :order => [:updated_at.desc]
  end
  
  def video_id
    url.gsub(/.*youtube.com\/watch\?v=/, '').gsub(/&.*/, '')
  end

  def self.latest
    self.first :order => [:updated_at.desc]
  end

  def to_json
    hash = self.attributes
    hash[:video_id] = self.video_id
    hash.to_json
  end

end
