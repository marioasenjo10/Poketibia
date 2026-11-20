-- Dinero solo en el banco (estilo PKA): no hay monedas en el inventario.
-- Vender a un NPC ingresa en el banco y comprar cobra del banco.
OPCODE_BANK = 64
COIN_VALUES = { [2148] = 1, [2152] = 100, [2160] = 10000 }

-- funciones originales del motor (solo se guardan la primera vez, por si se recarga la lib)
BankRaw = BankRaw or {
	getMoney = Player.getMoney,
	removeMoney = Player.removeMoney,
	addItem = Player.addItem,
	setBankBalance = Player.setBankBalance
}

function Player.sendBankBalance(self)
	self:sendExtendedOpcode(OPCODE_BANK, tostring(self:getBankBalance()))
end

function Player.setBankBalance(self, amount)
	BankRaw.setBankBalance(self, amount)
	self:sendBankBalance()
	return true
end

function Player.getMoney(self)
	return self:getBankBalance()
end

function Player.addMoney(self, amount)
	amount = tonumber(amount) or 0
	if amount < 0 then
		return false
	end
	if amount > 0 then
		self:setBankBalance(self:getBankBalance() + amount)
	end
	return true
end

function Player.removeMoney(self, amount)
	amount = tonumber(amount) or 0
	if amount < 0 then
		return false
	end
	local balance = self:getBankBalance()
	if balance < amount then
		return false
	end
	self:setBankBalance(balance - amount)
	return true
end

-- cualquier premio en monedas va directo al banco
function Player.addItem(self, itemId, ...)
	local id = tonumber(itemId) or ItemType(itemId):getId()
	local value = COIN_VALUES[id]
	if value then
		local count = ...
		local amount = math.max(1, tonumber(count) or 1) * value
		self:addMoney(amount)
		self:sendTextMessage(MESSAGE_INFO_DESCR, "Se han ingresado $" .. amount .. " en tu banco.")
		return true
	end
	-- se pasan los argumentos tal cual (un nil explicito cambiaria los valores por defecto del motor)
	return BankRaw.addItem(self, itemId, ...)
end

-- monedas antiguas que lleve encima -> al banco
function Player.convertCoinsToBank(self)
	local coins = BankRaw.getMoney(self)
	if coins > 0 and BankRaw.removeMoney(self, coins) then
		self:addMoney(coins)
		self:sendTextMessage(MESSAGE_INFO_DESCR, "Tus monedas ($" .. coins .. ") se han ingresado en tu banco.")
	end
end
