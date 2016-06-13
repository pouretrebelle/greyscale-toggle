require 'filewatcher'
require 'fileutils'
require 'yaml'


# methods
def get_filename(filename)
  return filename.split('/')[1..-1].join('/')
end
def copy_file(src, dest)
  FileUtils.cp src, dest + '/' + get_filename(src)
end
def remove_file(src, dest)
  FileUtils.rm dest + '/' + get_filename(src), :force => true
  puts 'File removed: ' + src + ' (' + dest + ')'
end
def get_config
  $config = YAML.load_file('config.yml')
end
def copy_to_current
  if $colour
    FileUtils.cp_r 'colour/.', 'current'
  else
    FileUtils.cp_r 'greyscale/.', 'current'
  end
end
def process_colour(filename)
  system('convert ' + filename + ' ' + ($convert_colour || '') + ' colour/' + get_filename(filename))
end
def process_greyscale(filename)
  system('convert ' + filename + ' ' + ($convert_greyscale || '') + ' greyscale/' + get_filename(filename))
end


# set variables
get_config
$colour = $config['colour']
$convert_colour = $config['convert_colour']
$convert_greyscale = $config['convert_greyscale']


# check that all original filenames exist in colour and greyscale
# copy and process them if not
Dir.foreach('original') do |filename|
  next if filename == '.' or filename == '..'
  if !File.exist?('colour/' + filename)
    process_colour 'original/' + filename
    puts 'File processed: ' + filename + ' (colour)'
  end
  if !File.exist?('greyscale/' + filename)
    process_greyscale 'original/' + filename
    puts 'File processed: ' + filename + ' (greyscale)'
  end
end


# delete processed files if they're not in original
Dir.foreach('colour') do |filename|
  next if filename == '.' or filename == '..'
  if !File.exist?('original/' + filename)
    remove_file filename, 'colour'
  end
end
Dir.foreach('greyscale') do |filename|
  next if filename == '.' or filename == '..'
  if !File.exist?('original/' + filename)
    remove_file filename, 'greyscale'
  end
end


# overwrite all current with correct copy
copy_to_current


# watch files
FileWatcher.new('**/*.*', spinner: true).watch() do |filename, event|

  if (event == :new)
    puts 'File added: ' + filename
  elsif (event == :changed)
    puts 'File updated: ' + filename
  elsif (event == :delete)
    puts 'File deleted: ' + filename
  end

  if filename == 'config.yml'
    get_config
    # toggle toggled
    if ($colour != $config['colour'])
      $colour = $config['colour']
      if $colour
        puts 'Toggled to colour'
      else
        puts 'Toggled to greyscale'
      end
    end
    # colour config changed
    if ($convert_colour != $config['convert_colour'])
      puts 'Colour config changed'
      $convert_colour = $config['convert_colour']
      Dir.foreach('original') do |image_filename|
        next if image_filename == '.' or image_filename == '..'
        process_colour 'original/' + image_filename
        puts 'File processed: ' + image_filename + ' (colour)'
      end
    end
    # greyscale config changed
    if ($convert_greyscale != $config['convert_greyscale'])
      puts 'Greyscale config changed'
      $convert_greyscale = $config['convert_greyscale']
      Dir.foreach('original') do |image_filename|
        next if image_filename == '.' or image_filename == '..'
        process_greyscale 'original/' + image_filename
        puts 'File processed: ' + image_filename + ' (greyscale)'
      end
    end
    # copy from the correct folder
    copy_to_current
  end

  folder = filename.split('/')[0]
  case folder

  when 'original'
    # if changed or new
    if (event == :changed || event == :new)
      process_colour filename
      process_greyscale filename
    end
    # if removed
    if (event == :delete)
      # remove colour, greyscale and current copy
      remove_file filename, 'colour'
      remove_file filename, 'greyscale'
      remove_file filename, 'current'
    end

  when 'colour'
    # if changed and colour is true
    if (event == :changed || event == :new)
      if $colour
        # copy to current
        copy_file filename, 'current'
      end
    end

  when 'greyscale'
    # if changed and colour is true
    if (event == :changed || event == :new)
      if !$colour
        # copy to current
        copy_file filename, 'current'
      end
    end

  when 'current'
    # if changed
    if (event == :changed || event == :new)
      # copy back to original folder
      if $colour
        copy_file filename, 'colour'
      else
        copy_file filename, 'greyscale'
      end
    end
    if (event == :delete)
      # delete original
      remove_file filename, 'original'
    end

  end

end
