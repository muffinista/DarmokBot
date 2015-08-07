#!/usr/bin/env ruby

require 'rubygems'
require 'chatterbot/dsl'
require 'wordnik'
require 'yaml'
require 'tilt'
require 'possessive'
require 'linguistics'

require 'engtagger'
require 'tilt/string'


#
# this is the script for the twitter bot DarmokBot
# generated on 2014-01-15 13:17:26 -0500
#

Wordnik.configure do |config|
  config.api_key = 'your key here'
  config.logger = Logger.new('/dev/null')
end


#
# I disabled caching because the file was getting corrupted somehow
#

#if ! File.exist?("words.yml")
@cache = { }
#else
#  @cache = YAML::load(File.read("words.yml"))
#end 

verbose

def tgr
  @tgr ||= EngTagger.new
end

def pluck_phrase(rem)
  rem = rem.split(/\.\?\!\,/).first

  foo = tgr.get_noun_phrases(tgr.add_tags(rem))
  sorted = foo.keys.flatten.flatten.reject { |x| x =~ /same time/ } #group_by(&:size)
end


@start_id = since_id
def load_phrase(p)
  key = p.gsub(/ /, "_").to_sym
  @cache[key] ||= []  

  search("'#{p}'", :lang => "en", :since_id => @start_id) do |tweet|
    next if tweet[:text] =~ /http/ || tweet[:text] =~ /@/
    rem = tweet[:text].match(/#{p} .*/i)
    @cache[key] = @cache[key] + pluck_phrase(rem[0]).flatten if rem
  end

  @cache[key]
end

def load_at_the
  load_phrase("at the")
end

def load_on_the
  load_phrase("on the")  
end

def load_when_the
  load_phrase("when the")  
end

# search twitter for 'at the'
def at_the
  @loaded_at_the ||= load_at_the
  @cache[:at_the].sample
end

# search twitter for 'on the'
def on_the
  @loaded_on_the ||= load_on_the
  @cache[:on_the].sample
end

def when_the
  @loaded_when_the ||= load_when_the
  @cache[:when_the].reject { |s| s =~ /ing/ }.sample
end

def file_to_array(f)
  x = []
  File.read(f).each_line { |l|
    x << l.chomp
  }
  x
end

def random_line
  @lines ||= file_to_array("list.txt")
  @lines.sample
end

def load_body_parts
  x = []
  File.read("body_parts.txt").each_line { |l|
    x << l.chomp
  }
  x
end

def body_part
  @body_parts ||= load_body_parts
  @body_parts.sample
end

def load_words(type)
  Wordnik.words.get_random_words(:limit => 100,
                                 :min_corpus_count => 5,
                                 :include_part_of_speech => type,
                                 :exclude_part_of_speech => "noun-plural,proper-noun").collect { |x| x["word"] }
end

def word
  @cache[:word] ||= []
  @cache[:word] = @cache[:word] + Wordnik.words.get_random_words(:limit => 100).collect { |x| x["word"] }
  @cache[:word].sample  
end


def noun
  @cache[:noun] ||= []
  @cache[:noun] = @cache[:noun] + load_words('noun')
  @cache[:noun].sample.singularize
end

def nouns
  noun.pluralize
end

def verb
  @cache[:verb] ||= []
  @cache[:verb] = @cache[:verb] + load_words('verb')
  @cache[:verb].sample
end

def _ed
  Linguistics.use( :en )
  v = @cache[:verb].sample
  v =~ /ed$/ ? v : v.en.infinitive.en.past_tense
end

def verbed
  verb
  x = _ed
  while x == "ed"
    x = _ed
  end
  x
end

def load_colors
  x = []
  File.read("colors.txt").each_line { |l|
    x << l.chomp
  }
  x
end

def color
  @colors ||= load_colors
  @colors.sample
end

def open_or_closed
  ["open", "closed"].sample
end

bot

def render(str)
  t = Tilt::StringTemplate.new { str }
  t.render(self)
end

def fell
  "fell"
end

x = render(random_line)
tweet x unless x.length < 20



File.open('words.yml', 'w') {|f| f.write(@cache.to_yaml) }
