local capi = {screen=screen,client=client}
local wibox = require("wibox")
local awful = require("awful")
local cairo        = require( "lgi"          ).cairo
local color        = require( "gears.color"  )
local beautiful    = require( "beautiful"    )
local surface      = require( "gears.surface" )
local pango = require("lgi").Pango
local pangocairo = require("lgi").PangoCairo
local module = {}

local w = nil
local rad = 10

local function init()
  w = wibox{}
  w.ontop = true
  w.visible = true
end

local function get_round_rect(width,height,bg)
  local img2 = cairo.ImageSurface(cairo.Format.ARGB32, width,height)
  local cr2 = cairo.Context(img2)
  cr2:set_source_rgba(0,0,0,0)
  cr2:paint()
  cr2:set_source(bg)
  cr2:arc(rad,rad,rad,0,2*math.pi)
  cr2:arc(width-rad,rad,rad,0,2*math.pi)
  cr2:arc(rad  ,height-rad,rad,0,2*math.pi)
  cr2:fill()
  cr2:arc(width-rad,height-rad,rad,0,2*math.pi)
  cr2:rectangle(rad,0,width-2*rad,height)
  cr2:rectangle(0,rad,rad,height-2*rad)
  cr2:rectangle(width-rad,rad,rad,height-2*rad)
  cr2:fill()
  return img2
end

local pango_l = nil
local function draw_shape(s)
  local clients = awful.client.tiled(s)
  local geo = capi.screen[s].geometry
  local wa  =capi.screen[s].workarea

  --Compute thumb dimensions
  local margins = 2*20 + (#clients-1)*20
  local width = (geo.width - margins) / #clients
  local ratio = geo.height/geo.width
  local height = width*ratio
  local dx = 20

  -- Do not let the thumb get too big
  if height > 150 then
    height = 150
    width = 150 * (1.0/ratio)
    dx = (wa.width-margins-(#clients*width))/2 + 20
  end

  -- Resize the wibox
  w.x,w.y,w.width,w.height = geo.x,wa.y+wa.height - 15 - height,geo.width,height

  local img = cairo.ImageSurface(cairo.Format.ARGB32, geo.width,geo.height)
  local img3 = cairo.ImageSurface(cairo.Format.ARGB32, geo.width,geo.height)
  local cr = cairo.Context(img)
  local cr3 = cairo.Context(img3)
  cr:set_source_rgba(0,0,0,0)
  cr:paint()

  local white,bg = color("#FFFFFF"),color(beautiful.menu_bg_normal or beautiful.bg_normal)
  local img2 = get_round_rect(width,height,white)
  local img4 = get_round_rect(width-6,height-6,bg)

  if not pango_l then
    local pango_crx = pangocairo.font_map_get_default():create_context()
    pango_l = pango.Layout.new(pango_crx)
    pango_l:set_font_description(beautiful.get_font(font))
    pango_l:set_alignment("CENTER")
    pango_l:set_wrap("CHAR")
  end

  local nornal,focus = color(beautiful.fg_normal),color(beautiful.bg_urgent)
  for k,v in ipairs(clients) do
    -- Shape bounding
    cr:set_source_surface(img2,dx,0)
    cr:paint()

    -- Borders
    cr3:set_source(v==capi.client.focus and focus or nornal)
    cr3:rectangle(dx,0,width,height)
    cr3:fill()
    cr3:set_source_surface(img4,dx+3,3)
    cr3:paint()

    -- Print the icon
    cr:set_source_surface(surface(v.icon),dx,10)
    cr:paint()

    -- Pring the text
    cr3:set_source(nornal)
    pango_l.text = v.name
    pango_l.width = pango.units_from_double(width-16)
    pango_l.height = pango.units_from_double(height-40)
    cr3:move_to(dx+8,40)
    cr3:show_layout(pango_l)

    dx = dx + width + 20
  end

  w:set_bg(cairo.Pattern.create_for_surface(img3))
  w.shape_bounding = img._native
  w.visible = true
end

function module.display_clients(s)
  if not w then
    init()
  end
  draw_shape(s)
end

function module.hide()
  w.visible = false
end

function module.change_focus(mod,key,event,direction,is_swap,is_max)
  awful.client.focus.byidx(direction == "right" and 1 or -1)
  draw_shape(capi.client.focus.screen)
  return true
end

return module
-- kate: space-indent on; indent-width 2; replace-tabs on;