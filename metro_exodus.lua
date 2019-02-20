local sprintf = string.format
local function wprintf(s, ...)
 ODS ( sprintf(s,...) )
end

suffix = ''
discard = false

function parse_save(ofs)

 if string.find(save_file, '_save') == nil then
    wprintf ('#REJECT: unaccepted save_file [~C0A%s~C07]', save_file)
    discard = true
    return ''
 end
 
 tag = fread_str(0, 4)
 
 if tag == 'artm' then -- chapter start save   
   lvl = fread_str(44, 16) -- just read level name 
   suffix = lvl
   return lvl
 end
 
 if tag == 'DEZP' then -- typical checkpoint/qucksave     
   -- just read level name
   lvl = fread_str(73, 16) 
   suffix = lvl
   return lvl
 end
 
  
 wprintf('#REJECT: unaccepted save tag [~C0F%s~C07]', tag); 
 
 return '' 
end