-- @docclass
-- Barra en forma de pastilla con el relleno tambien redondeado (PokeDash).
-- UIProgressBar pinta el relleno como un rectangulo de color; aqui el relleno es una imagen
-- redondeada y suavizada (hijo "fill"), tenida del color que toque y con el ancho del
-- porcentaje, asi los dos extremos se ven lisos aunque la barra no este llena.
-- Mismos metodos que se usaban de UIProgressBar: setPercent, getPercent, setBackgroundColor
-- (tine el relleno) y setText (el texto va en el hijo "label", por encima del relleno).
-- Estilos: PillBar / ThinBar en data/styles/35-pills.otui. Propiedad de estilo: fill-color.
UIPillBar = extends(UIWidget, "UIPillBar")

function UIPillBar.create()
  local bar = UIPillBar.internalCreate()
  bar:setFocusable(false)
  bar.percent = 0
  bar.fillColor = '#2f9e44'
  return bar
end

function UIPillBar:onStyleApply(styleName, styleNode)
  for name, value in pairs(styleNode) do
    if name == 'fill-color' then
      self.fillColor = value
    end
  end
end

function UIPillBar:updateFill()
  local fill = self:getChildById('fill')
  if not fill then return end
  local width, height = self:getWidth(), self:getHeight()
  if self.percent <= 0 or width <= 0 then
    fill:setVisible(false)
    return
  end
  -- nunca mas estrecho que su alto: asi siempre es una pastilla, no un rectangulo
  local fillWidth = math.floor(width * self.percent / 100 + 0.5)
  fill:setWidth(math.max(height, math.min(width, fillWidth)))
  fill:setImageColor(self.fillColor)
  fill:setVisible(true)
end

function UIPillBar:setPercent(percent)
  self.percent = math.max(0, math.min(100, tonumber(percent) or 0))
  self:updateFill()
end

function UIPillBar:getPercent()
  return self.percent
end

-- el color va al relleno (no al fondo del widget)
function UIPillBar:setBackgroundColor(color)
  self.fillColor = color
  self:updateFill()
end

function UIPillBar:setText(text)
  local label = self:getChildById('label')
  if label then label:setText(text) end
end

function UIPillBar:getText()
  local label = self:getChildById('label')
  return label and label:getText() or ''
end

function UIPillBar:onSetup()
  self:updateFill()
end

function UIPillBar:onGeometryChange()
  self:updateFill()
end
