--[[
Copyright (c) 2025, Aravix
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of autoinvite nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Registry BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
]]

require('luau')

_addon.name = 'STFU'
_addon.author = 'Aravix'
_addon.commands = {'stfu'}
_addon.version = 1.0
_addon.language = 'english'

defaults = T{}
defaults.blacklist = S{}
defaults.blisted_db = S{}


add_aliases = S{'add', 'a'}
remove_aliases = S{'remove', 'rm', 'r'}
list_aliases = S{'list', 'l', 'ls'}
help_aliases = S{"help", 'h'}



settings = config.load(defaults)

windower.register_event('chat message', function(message, player, mode, is_gm)
    local match = false

    if mode ~= 26 then
        return
    end

    for item in settings.blacklist:it() do
            if message:lower():match(item:lower()) then
                match = true
            break
        end
    end

    if not match then
        return
    else
        local p = (player or ''):lower()
        if settings.blisted_db:contains(p) then
            return
        end

        windower.send_command('input /blist add '..player)
        log(player..' was blacklisted!')
        settings.blisted_db = settings.blisted_db + S{p}
        config.save(settings)
    end

end)

function add_keyword_to_blacklist(...)
    local words = S{...}:map(function(w)
        return (w or ''):lower()
    end)

    if words:empty() then
        notice('No word specified to add.')
        return
    end

    local existing = words * settings.blacklist
    if not existing:empty() then
        notice('Word':plural(existing)..' '..existing:format()..' already exists on blacklist.')
    end

    local new = words - settings.blacklist
    if not new:empty() then
        settings.blacklist = settings.blacklist + new
        log('Added '..new:format()..' to blacklist.')
    end

    config.save(settings)
end

function remove_keyword_from_blacklist(...)
    local words = S{...}:map(function(w)
        return (w or ''):lower()
    end)

    if words:empty() then
        notice('No word specified to remove.')
        return
    end

    local to_remove = words * settings.blacklist
    if to_remove:empty() then
        notice('No matching word found to remove from blacklist.')
    else
        settings.blacklist = settings.blacklist - to_remove
        log('Removed '..to_remove:format()..' from blacklist.')
        config.save(settings)
    end
end

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = L{...}
    
    if add_aliases:contains(command) then
        local words = args:map(function(w)
            return (w or ''):lower()
        end)
        add_keyword_to_blacklist(words:unpack())
    elseif remove_aliases:contains(command) then
        local words = args:map(function(w)
            return (w or ''):lower()
        end)
        remove_keyword_from_blacklist(words:unpack())
    elseif list_aliases:contains(command) then
        if settings.blacklist:empty() then
            log('The STFU blacklist is currently empty.')
        else
            log('The currently blacklisted words in STFU are as follows:')
            log(settings.blacklist:format('csv'))
        end
    elseif help_aliases:contains(command) then
        log('-- STFU --')
        log('STFU is an addon that automatically blacklists players who writes certain words.')
        log("Its goal is to reduce headaches from RMT spam in /yell chat.")
        log('')
        log('-- STFU Commands --')
        log('//stfu list - Lists all blacklisted words.')
        log('//stfu add <word1> <word2> ... - Adds words to the blacklist.')
        log('//stfu remove <word1> <word2> ... - Removes words from the blacklist.')
    end

    config.save(settings)
end)
