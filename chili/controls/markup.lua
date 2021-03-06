-- TODO: combine 'html > table > chili' into 'html > chili'
--        flex html library to create chili objects instead of creating a table
-- TODO: enable 'head' where scripts, css, and psuedonyms* can be defined and handled seperately from the html layout
--        *a psuedonym will be any tag that is tied to a usable chili class other than
--         it can be treated like a 'themed' class, or could be used for convenience

Markup = Control:Inherit{
  classname = 'Markup',
  height = '100%',
  width = '100%',
  styles = {},
  ignoreBuild = {
    style = true,
    script = true,
    Script = true,
    Style = true
  },
  tags = {
    label = TextBox,
    p = TextBox,
    textbox = TextBox,
    panel = Panel,
    div = Panel,
    window = Window,
    button = Button,
    stackpanel = StackPanel,

  }
}

local this = Markup
local inherited = this.inherited

HTML_DIR = 'luaui/libs/html/'
--//=============================================================================

function Markup:New(obj)
  obj = inherited.New(self,obj)
  local html_table = VFS.Include(HTML_DIR..'html.lua')(obj.html or '')
  obj:Parse(html_table, obj)
  return obj
end

function Markup:BuildChili(tag, obj)
  -- Merge obj with styles
  local styles = self.styles
  for k, v in pairs(styles[tag] or {}) do obj[k] = v end       -- Elements
  for k, v in pairs(styles[obj.class] or {}) do obj[k] = v end -- Classes
  for k, v in pairs(styles[obj.name] or {}) do obj[k] = v end  -- ID

  -- will need to replace
  local Class = self.tags[tag]
  if not Class then
    return Control:New(obj)
  end

  return Class:New(obj)
end

function Markup:Parse(root, parent)
  parent = parent or self
  -- TODO: Detect <script></script> tags
  --     : create definable class obj (css?) that merge with HTML obj
  for k, v in pairs(root) do
    if self:type(k,v) == 'content' then
      if root._tag:lower() == 'script' then
        loadstring(v)()
      -- elseif root._tag:lower() =='style' then
      --   Spring.Echo(v)
      --   self:AddStyles(v)
      elseif parent.text then
        parent:SetText(v)
      elseif parent.caption then
        parent:SetCaption(v)
      end
    end

    if self:type(k,v) == 'element' then
      if v._tag:lower() =='style' then self:AddStyles(v[1]) end
      v._attr.parent = parent
      self:Parse(v, self:BuildChili(v._tag, v._attr))
    end
  end
end

function Markup:AddStyles(s)
  for sel, content in s:gmatch('(.-){(.-)}') do
    -- grabs all selectors, ignores stacking selectors for now
    sel = sel:match('%w+') or sel
    if not self.styles[sel] then self.styles[sel] = {} end
    for key, val in content:gmatch('([^%s]-):%s*(.-)%s*;') do
      if val:match(',') then
        local vTable = {}
        for tVal in val:gmatch('(%w+)') do
          vTable[#vTable + 1]= tonumber(tVal)
        end
        self.styles[sel][key] = vTable
      else
        self.styles[sel][key] = val
      end
    end
  end
end

function Markup:type(k, v)
  return k ~= '_tag' and k ~= '_attr' and type(v) == 'table' and 'element' or
         k ~= '_tag' and k ~= '_attr' and type(v) == 'string' and 'content'
end
