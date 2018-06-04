local app_name = "VlcPrevNext"
local app_sig = "[" .. app_name .. "]"
local app_version = "0.0.1"
local app_title = app_name .. " " .. app_version
local app_description = "Adds previous and next files from the same directory to the playlist."
local app_short_desc = "Load prev/next file"
local media_extensions = {".mp4", ".m4v", ".avi", ".wmv", ".mkv", ".mov", ".mpeg", ".mpg"}


-- VLC HOOKS

-- Describes the extension.
---------------------------
function descriptor()

    return { 
        title = app_title,
        version = app_version,
        author = "djomlastic",
        description = app_description,
        shortdesc = app_short_desc,
        capabilities = {"input-listener"}
    }
end

-- Called when extension is activated.
--------------------------------------
function activate()

    log(" active.")

    input_changed()
end

-- Called when extension is deactivated.
----------------------------------------
function deactivate()

    log(" over and out.")
end

-- So vlc doesn't clutter the log with warnings.
------------------------------------------------
function meta_changed()

    return false
end

-- Note: For some reason Vlc triggers this function twice when new file
--       plays. So we'll add some meta to the item we processed to be
--       be able to track state and avoid processing the same file twice.
-------------------------------------------------------------------------
-- Called when input changes (new file plays).
----------------------------------------------
function input_changed()

    local item = vlc.item or vlc.input.item()
    if not item then
        log(" didn't find vlc.item.")
        return
    end

    if item:metas()[app_name] then
        return
    end

    load_prev_next(item)

    item:set_meta(app_name, "File processed.")
end


-- FUNCTIONS

-- Note: Vlc creates playlist titles from meta (or some other way), and often
--       happens that those titles are sorted differently than file names. We
--       use file names to select next and previous files, and if we then use
--       vlc.playlist.sort("title") we might end up not having previous or next
--       file, even though we do. We end up having two next or previous files.
--       So instead of vlc.playlist.sort("title") we'll use vlc.playlist.move()
--       to move previous file in the playlist before the current one.
------------------------------------------------------------------------------
-- Clears playlist and adds previous and next file from the item's directory.
-- @param item: vlc.item.
-------------------------
function load_prev_next(item)
    
    if not clean_vlc_playlist() then
        log(" could not clean vlc playlist.")
        return
    end
    
    local dir_path = get_directory_path(item)
    local dir_file_names = vlc.net.opendir(dir_path)
    local media_file_names = get_valid_files(dir_file_names, media_extensions)
    local media_files_count = #media_file_names
    
    if media_files_count < 2 then
        log(" didn't find adjecent media files.")
        return
    end
    
    table.sort(media_file_names, is_first_string_less)
    
    local current_media_file_index = find_key(get_file_name(item), media_file_names)
    
    if not current_media_file_index then
        log(" current file not found within valid media files.")
        return
    end
    
    -- add previous, or last file if there are more then 2 media files
    if media_file_names[current_media_file_index - 1] then
        add_file_to_playlist(media_file_names[current_media_file_index - 1], dir_path)
        last_file_to_first_position()
    elseif media_files_count >= 3 then
        add_file_to_playlist(media_file_names[media_files_count], dir_path)
        last_file_to_first_position()
    end
    
    -- add next, or first file if there are more than 2 media files
    if media_file_names[current_media_file_index + 1] then
        add_file_to_playlist(media_file_names[current_media_file_index + 1], dir_path)
    elseif media_files_count >= 3 then
        add_file_to_playlist(media_file_names[1], dir_path)
    end
end

-- Determines if the OS is Windows.
-- @returns: true if we're running under Windows, false otherwise.
------------------------------------------------------------------
function is_windows()

    -- vlc.win module exists only in Windows builds
    if vlc.win then
        return true
    end

    return false
end

-- Gets path to item's directory (removes protocol "file:///").
-- @param item: vlc.item.
-- @returns: absolute path to item's directory.
-----------------------------------------------
function get_directory_path(item)

    local dir_uri = item:uri():match("(.*[/\\])")
    local decoded_uri = vlc.strings.decode_uri(dir_uri)

    if is_windows() then
        return decoded_uri:gsub("file:///", "")
    end

    return decoded_uri:gsub("file://", "")
end

-- Gets item's file name (item:name() is not consistent).
-- @param item: vlc.item.
-- @returns: item's file name.
------------------------------
function get_file_name(item)

    local file_name = item:uri():match("([^/\\]*)$")

    return vlc.strings.decode_uri(file_name)
end

-- Removes files with invalid extensions.
-- @param files: array of file paths.
-- @param valid_extensions: array of valid extensions.
-- @returns: Array containint only file paths with valid extensions.
--------------------------------------------------------------------
function get_valid_files(files, valid_extensions)

    local valid_files = {}

    for key, file_path in pairs(files) do
        if is_file_extension_valid(file_path, valid_extensions) then
            table.insert(valid_files, file_path)
        end
    end

    return valid_files
end

-- Checks if file path's extension exists within valid_extensions.
-- @param file_path: file path.
-- @param valid_extensions: array of valid extensions.
-- @returns: true if file path's extension is found within valid_extensions, false otherwise.
---------------------------------------------------------------------------------------------
function is_file_extension_valid(file_path, valid_extensions)

    local extension = file_path:match("(%.[^%.]*)$")

    for key, value in pairs(valid_extensions) do
        if value == extension then
            return true
        end
    end

    return false
end

-- Removes all items from vlc playlist except the current item.
-- @returns: true on success, false otherwise.
----------------------------------------------
function clean_vlc_playlist()

    local current_item_id = vlc.playlist.current()

    if not current_item_id then
        log(" could not find current playlist item.")
        return false
    end

    local playlist = vlc.playlist.get("playlist")
    
    if not playlist or not playlist.children then
        log(" could not retrieve the playlist.")
        return false
    end

    for index, item in pairs(playlist.children) do
        if item.id and item.id ~= current_item_id then
            vlc.playlist.delete(item.id)
        end
    end

    return true
end

-- Adds a file to vlc playlist.
-- @param file_name: name of the file.
-- @param directory_path: path to file's directory.
---------------------------------------------------
function add_file_to_playlist(file_name, directory_path)

    local item = {}

    if is_windows() then
        item.path = "file:///" .. directory_path .. file_name
    else
        -- vlc.strings.make_uri returns nil in Windows
        item.path = vlc.strings.make_uri(directory_path .. file_name, "file")
    end

    vlc.playlist.enqueue({item})
end

-- Moves last file in vlc's playlist to first position.
-------------------------------------------------------
function last_file_to_first_position()

    local playlist = vlc.playlist.get("playlist")

    if not playlist or not playlist.id or not playlist.children or #playlist.children < 2 then
        log(" could not move file before the current file.")
        return
    end

    vlc.playlist.move(playlist.children[#playlist.children].id, playlist.id)
end


-- HELPERS

-- Note: For some reason string comparison is wierd with vlc 2.2.2 Linux build,
--       for example ("foo 1 bar" < "foo 11 bar") returns false. Vlc 2.2.2 and
--       3.0.3 Windows builds don't have the issue, given example returns true.
--       So we'll use this function to sort file names.
------------------------------------------------------------------------------
-- Compares two strings.
-- @param first: first string.
-- @param second: second string.
-- @returns: true if first string is less then second, false otherwise.
function is_first_string_less(first, second)

    local first_length = #first
    local second_length = #second
    local counter

    if first_length < second_length then
        counter = first_length
    else
        counter = second_length
    end

    for i = 1, counter do
        if first:sub(i, i) ~= second:sub(i, i) then
            return first:sub(i, i) < second:sub(i, i)
        end
    end

    return first_length < second_length
end

-- Finds key for a value within a table.
-- @param needle: value whose key we want to find.
-- @param haystack: table to search.
-- @returns: key if it was found, nil otherwise.
------------------------------------------------
function find_key(needle, haystack)
    
    if type(haystack) ~= "table" then
        return nil
    end

    for key, value in pairs(haystack) do
        if value == needle then
            return key
        end
    end

    return nil
end

-- Writes debugging message.
-- @param message: message to write.
------------------------------------
function log(message)

    vlc.msg.dbg(app_sig .. message)
end

-- Dumps a variable.
-- @param var: variable to dump.
--------------------------------
function dump(var)

    if type(var) == "table" then
        local output = "{ "

        for key, value in pairs(var) do
            if type(key) ~= "number" then
                key = "\"" .. key .. "\""
            end

            output = output .. "["..key.."] = " .. dump(value) .. ","
       end

       return output .. "} "
    else
       return tostring(var)
    end
end