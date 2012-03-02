require "cabin"
require "json"

# Wrap IO objects with a reasonable log output. 
#
# If the IO is *not* attached to a tty (io#tty? returns false), then
# the event will be written in json format terminated by a newline:
#
#     { "timestamp": ..., "message": message, ... }
#
# If the IO is attached to a TTY, there are # human-friendly in this format:
#
#     message {json data}
#
# Additionally, colorized output may be available. If the event has :level,
# :color, or :bold. Any of the Cabin::Mixins::Logger methods (info, error, etc)
# will result in colored output. See the LEVELMAP for the mapping of levels
# to colors.
class Cabin::Outputs::IO
  # Mapping of color/style names to ANSI control values
  CODEMAP = {
    :normal => 0,
    :bold => 1,
    :black => 30,
    :red => 31,
    :green => 32,
    :yellow => 33,
    :blue => 34,
    :magenta => 35,
    :cyan => 36,
    :white => 37
  }

  # Map of log levels to colors
  LEVELMAP = {
    :fatal => :red,
    :error => :red,
    :warn => :yellow,
    :info => nil, # default color
    :debug => :cyan,
  }

  def initialize(io)
    @io = io
  end # def initialize

  # Receive an event
  def <<(event)
    if !@io.tty?
      @io.puts(event.to_json)
    else
      tty_write(event)
    end
  end # def <<

  private
  def tty_write(event)
    # The io is attached to a tty, so make pretty colors.
    # delete things from the 'data' portion that's not really data.
    data = event.clone
    data.delete(:message)
    data.delete(:timestamp)

    color = data.delete(:color)
    # :bold is expected to be truthy
    bold = data.delete(:bold) ? :bold : nil

    # Make 'error' and other log levels have color
    if color.nil? and data[:level]
      color = LEVELMAP[data[:level]]
    end

    if data.empty?
      message = [event[:message]]
    else
      message = ["#{event[:message]} #{data.to_json}"]
    end
    message.unshift("\e[#{CODEMAP[color.to_sym]}m") if !color.nil?
    message.unshift("\e[#{CODEMAP[bold]}m") if !bold.nil?
    message.push("\e[#0m") if !(bold.nil? and color.nil?)
    @io.puts(message.join(""))
    @io.flush
  end # def <<

  public(:initialize, :<<)
end # class Cabin::Outputs::StdlibLogger
