require 'rubygems'
require 'gosu'
require 'tk'

MAX_TRACK = 15

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

class Track
  attr_accessor :name, :location
  def initialize (name='', location='')
    @name = name
    @location = location
  end
end

class Album
  attr_accessor :title, :artist, :artwork, :tracks
  def initialize (title='', artist='', artwork='', tracks='')
    @title = title
    @artist = artist
    @artwork = artwork
    @tracks = tracks
  end
end

class MusicPlayerMain < Gosu::Window

	def initialize
	    super 800, 600
	    self.caption = "Music Player"
      @locs = [0,0]
      @track_font = Gosu::Font.new(20)
      @info_font = Gosu::Font.new(20)
      @button_font = Gosu::Font.new(16)
      @albums = read_albums_file ('albums.txt')
      @current_track = -1
      @current_page = 0
      @pages = read_pages(@albums)
      @current_album = @pages[0][0]
      @playing_album = @pages[0][0]
      @playlist = []
      @playlist_array = []
      @check_draw_temporary_playlist = false
	end

# Put in your code here to load albums and tracks-------------------------------------------------
  def read_track (music_file)
      name = music_file.gets
      location = music_file.gets
      track = Track.new(name,location)
      return track
  end
  def read_tracks (music_file)
      number_of_tracks = music_file.gets.to_i
      tracks = Array.new()
      for i in 0..(number_of_tracks-1)
          tracks << read_track(music_file)
      end
      return tracks
  end

  def read_album(music_file)
    album_title = music_file.gets
    album_artist = music_file.gets
  	album_artwork = music_file.gets
    album_tracks = read_tracks(music_file)
    album = Album.new(album_title, album_artist, album_artwork, album_tracks)
    return album
  end

  def read_albums(music_file)
      number_of_albums = music_file.gets().to_i
      albums = Array.new()
      for i in 0..(number_of_albums-1)
          album = read_album(music_file)
          albums << album
      end
      return albums
  end

  def read_albums_file(file_name)
      music_file = File.new(file_name, "r")
      albums = read_albums(music_file)
      music_file.close()
      return albums
  end

  def read_page(albums, albums_index)
    page = Array.new()
    page_index = 0
    while (page_index < 4) and (albums_index < albums.length) # 4 albums per page
      page << albums[albums_index]
      albums_index += 1
      page_index += 1
    end
    return page
  end

  def read_pages(albums)
    pages = Array.new()
    albums_index = 0
    while albums_index < albums.length
      page = read_page(albums, albums_index)
      pages << page
      albums_index += 4
    end
    return pages
  end

  #--------------------------------------------------------------------------------------------------
    # Draws the artwork on the screen for all the albums

  def draw_background
    draw_quad(0, 0, TOP_COLOR, 800, 0, TOP_COLOR, 0, 600, BOTTOM_COLOR, 800, 600, BOTTOM_COLOR, ZOrder::BACKGROUND)
  end

  def draw_album(album,x,y)
    image = Gosu::Image.new(album.artwork.chomp)
    fx = 200.0/image.width
    fy = 200.0/image.height
    image.draw(x, y, ZOrder::PLAYER, fx, fy)
  end

  def draw_albums(pages)
    y=10 # y-padding
    i = 0
    while i < pages[@current_page].length
      x =10 # x-padding
      for j in 1..2
        if i < pages[@current_page].length
          draw_album(pages[@current_page][i], x, y)
          if area_clicked(x, y, x+200, y+200)
            @current_album = pages[@current_page][i]
          end
          x+=210
          i += 1
        end
      end
      y += 210
    end
  end

  def display_track(title, ypos)
    @track_font.draw(title, 600, ypos, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_tracks(album)
    y=0
    for i in 0..(album.tracks.length-1)
      display_track(album.tracks[i].name, y)
      y += 600/MAX_TRACK
    end
  end

  def draw_buttons
    y=10
    for i in (1..5)
      Gosu.draw_rect(440, y, 140, 20, Gosu::Color::GREEN, ZOrder::PLAYER, mode=:default)
      y += 30
    end
    @button_font.draw("Add current song", 450, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @button_font.draw("Save new playlist", 450, 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @button_font.draw("Open playlist", 450, 70, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @button_font.draw("Save playlist file", 450, 100, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    @button_font.draw("Open playlist file", 450, 130, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_flip_page
    @info_font.draw("Next Page>>", 320, 450, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_back_page
    @info_font.draw("<<Last Page", 0, 450, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_controls
    draw_triangle(10, 550, Gosu::Color::GREEN, 10, 570, Gosu::Color::GREEN, 30, 560, Gosu::Color::GREEN, ZOrder::PLAYER, mode=:default)
    Gosu.draw_rect(40, 550, 20, 20, Gosu::Color::GREEN, ZOrder::PLAYER, mode=:default)
  end

  def draw_info
    @info_font.draw("Playing album #{@playing_album.title.chomp} track #{@playing_album.tracks[@current_track].name.chomp}", 70, 550, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_page_info
    @info_font.draw("Page #{@current_page}", 190, 450, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    if @current_page < @pages.length-1
      draw_flip_page
    end
    if @current_page > 0
      draw_back_page
    end
  end

  def draw_playlist(playlist)
    y=160
    @button_font.draw("Playlist #{@playlist_array.length}", 450, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    y += 20
    for i in 0..(playlist.length-1)
      @button_font.draw("#{playlist[i].name}", 450, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      y += 20
    end
  end

  def draw
    draw_background()
    draw_albums(@pages)
    draw_tracks(@current_album)
    draw_buttons()
    if @check_draw_temporary_playlist
      draw_temporary_playlist(@playlist_array)
    else
      draw_playlist(@playlist)
    end
    if @current_track > -1
      draw_controls()
      draw_info()
    end
    draw_page_info()
  end

  def update
    if area_clicked(440, 10, 580, 30)
      add_to_playlist(@playlist)
      @check_draw_temporary_playlist = false
      @locs = [0,0]
    elsif area_clicked(440, 40, 580, 60)
      if @playlist != []
        save_temporary_playlist()
        @locs = [0,0]
      end
    elsif area_clicked(440, 70, 580, 90)
      @check_draw_temporary_playlist = true
      @loc= [0,0]
    elsif area_clicked(440, 100, 580, 120)
      if @playlist != []
        save_playlist_file(@playlist)
        @locs = [0,0]
      end
    elsif area_clicked(440, 130, 580, 150)
        open_playlist_file()
        @locs = [0,0]
    elsif area_clicked(10, 550, 30, 570)
      if @song != nil
        @song.play
        @locs = [0,0]
      end
    elsif area_clicked(40, 550, 60, 570)
      if @song != nil
        @song.pause
        @locs = [0,0]
      end
    elsif area_clicked(320, 450, 420, 470)
      if @current_page+1 < @pages.length
        @current_page += 1
        @locs = [0,0]
      end
    elsif area_clicked(0, 450, 100, 470)
      if @current_page > 0
        @current_page -= 1
        @locs = [0,0]
      end
    end
  end

  def open_playlist_file ()
    root = TkRoot.new
      root.title = "Open playlist"
    filetypes = [["Text Files", "*.txt"]]
    filename = Tk::getOpenFile('filetypes' => filetypes)
    if filename != ""
      afile = File.new(filename, "r")
      tracks = read_tracks(afile)
      afile.close()
      playlist_album = Album.new("playlist","playlist","playlist", tracks)
      @current_album = playlist_album
    end
  end

  def save_playlist_file(playlist)
    root = TkRoot.new
      root.title = "Save playlist"
    filetypes = [["Text Files", "*.txt"]]
    filename = Tk::getSaveFile('filetypes' => filetypes, 'defaultextension' => '.txt')
    if filename != ""
      afile = File.new(filename, "w")
      afile.puts(playlist.length)
      for i in (0..playlist.length-1)
        afile.puts(playlist[i].name)
        afile.puts(playlist[i].location)
      end
      afile.close()
      Tk::messageBox :message => "File is"+ filename
    end
  end

  def save_temporary_playlist
    @playlist_array << @playlist
    @playlist =[]
  end

  def draw_temporary_playlist(playlist_array)
    y=160
    for i in 0..(playlist_array.length-1)
      @button_font.draw("Playlist #{i}", 450, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      if area_clicked(450, y, 550, y+20)
        playlist_album = Album.new("playlist","playlist","playlist", playlist_array[i])
        @current_album = playlist_album
      end
      y += 30
    end
  end

  def add_to_playlist(playlist)
    track = @playing_album.tracks[@current_track]
    playlist << track
  end

  def playTrack(album, track)
     @song = Gosu::Song.new(album.tracks[track].location.chomp)
     @song.play(false)
  end

  def area_clicked(leftX, topY, rightX, bottomY)
      mouse_x = @locs[0]
      mouse_y = @locs[1]
    if ((mouse_x > leftX and mouse_x < rightX) and (mouse_y > topY and mouse_y < bottomY))
      true
    else
      false
    end
  end

  def needs_cursor?; true; end

  def button_down(id)
    case id
      when Gosu::MsLeft
        @locs = [mouse_x, mouse_y]
        leftX = 600
        rightX = 800
        if mouse_x<rightX and mouse_x>leftX
          for i in 0..@current_album.tracks.length-1
            topY = i*600/MAX_TRACK
            bottomY = (i+1)*600/MAX_TRACK
              if area_clicked(leftX, topY, rightX, bottomY)
                @current_track = i
                playTrack(@current_album, @current_track)
                @playing_album = @current_album
              end
          end
        end
    end
  end


end

MusicPlayerMain.new.show if __FILE__ == $0
