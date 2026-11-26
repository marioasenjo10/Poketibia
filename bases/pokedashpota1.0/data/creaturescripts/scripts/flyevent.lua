-- Al volar: suelo de aire en la casilla de destino y en un cuadrado alrededor (lib/core/flyfloor.lua),
-- para que el cliente pueda andar seguido sin esperar al servidor en cada paso.
function onMove(creature, toPosition, fromPosition)
	local player = Player(creature:getId())
	if player and player:isOnFly() then
		toPosition:createFlyFloor()
		updateFlyRing(player, toPosition)
	end
	return true
end
