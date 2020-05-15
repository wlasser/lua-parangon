--[[


   _______
  /       \
  $$$$$$$  | ______    ______   ______   _______    ______    ______   _______
  $$ |__$$ |/      \  /      \ /      \ /       \  /      \  /      \ /       \
  $$    $$/ $$$$$$  |/$$$$$$  |$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |$$$$$$$  |
  $$$$$$$/  /    $$ |$$ |  $$/ /    $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
  $$ |     /$$$$$$$ |$$ |     /$$$$$$$ |$$ |  $$ |$$ \__$$ |$$ \__$$ |$$ |  $$ |
  $$ |     $$    $$ |$$ |     $$    $$ |$$ |  $$ |$$    $$ |$$    $$/ $$ |  $$ |
  $$/       $$$$$$$/ $$/       $$$$$$$/ $$/   $$/  $$$$$$$ | $$$$$$/  $$/   $$/
                                                  /  \__$$ |
                                                  $$    $$/
                                                   $$$$$$/  Without AIO


  @Original_Author : iThorgrim

  This script allo player to up fake level like Parangon (Diablo 3) and allow to up statistiques.

  @iThorgrim_Github : https://github.com/Open-Wow
  @iThorgrim_Facebook : facebook.com/iThorgrim
  @iThorgrim_Site : https://open-wow.fr

  @AzerothCore Community : https://discord.gg/PaqQRkd
  @Open-Wow Community : https://discord.gg/mTHxKmY

  Thanks for your patience <3.

]]--
local Parangon = {};

Parangon.Config = {

  -- Amount of experience a kill brings
  pveKill = 50,
  pvpKill = 100,

  -- Max exp require for level 1 | maxExp * ParangonLevel
  maxExp = 500,

  -- Parangon points per Level
  pointsPerLevel = 2,

  -- Minimum level for Parangon
  minLevel = 70,

  -- DB Name .. so easy
  dbName = 'ac_eluna',

  -- Well .. it's just ... mmmh.. a spacer ?
  space = '       ';
};

CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Parangon.Config.dbName..'`.`account_parangon` (`accountid` int(11) NOT NULL, `level` int(11) DEFAULT 1, `exp` int(11) DEFAULT 0,PRIMARY KEY (`accountid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;');
CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Parangon.Config.dbName..'`.`characters_parangon` (`accountid` int(11) NOT NULL,`guid` int(11) NOT NULL, `strenght` int(11) NOT NULL DEFAULT 0, `agility` int(11) NOT NULL DEFAULT 0, `stamina` int(11) NOT NULL DEFAULT 0, `intellect` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`accountid`,`guid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;');

Parangon.Stats = {};
Parangon.Infos = {};

--[[
  Parangon.getParangon
    | - We apply auras to player
]]--
  function Parangon.setStats(player)
    local pLevel = player:GetLevel();

    if (pLevel >= Parangon.Config.minLevel) then
      local pGuid = player:GetGUIDLow();

      for spell, value in pairs (Parangon.Stats[pGuid]) do
        player:RemoveAura(spell);
        player:AddAura(spell, player);
        player:GetAura(spell):SetStackAmount(value);
      end
    end
  end

--[[
  Parangon.getParangon
    | - We create a function that will fetch the information during connection.
]]--

  -- Player get Parangon
  function Parangon.getParangon(event, player)
    local pGuid = player:GetGUIDLow();
    local pAccid = player:GetAccountId();

    if (not (Parangon.Stats[pGuid])) then
      --
      local getParangonStats = CharDBQuery("SELECT strenght, agility, stamina, intellect FROM `"..Parangon.Config.dbName.."`.characters_parangon WHERE guid = "..pGuid.." AND accountid = "..pAccid..";");
      --
      Parangon.Stats[pGuid] = {
        [7464] = getParangonStats:GetUInt32(0), -- Strenght
        [7471] = getParangonStats:GetUInt32(1), -- Agility
        [7477] = getParangonStats:GetUInt32(2), -- Stamina
        [7468] = getParangonStats:GetUInt32(3); -- Intellect
      };
    end

    if (not (Parangon.Infos[pAccid])) then
      --
      local getParangonInfo = CharDBQuery("SELECT level, exp FROM `"..Parangon.Config.dbName.."`.account_parangon WHERE accountid = "..pAccid..";");
      --
      Parangon.Infos[pAccid] = {
        level = getParangonInfo:GetUInt32(0),
        exp = getParangonInfo:GetUInt32(1);
      };
    end
    Parangon.Infos[pAccid].points = ((Parangon.Infos[pAccid].level * Parangon.Config.pointsPerLevel) - Parangon.Stats[pGuid][7464] - Parangon.Stats[pGuid][7471] - Parangon.Stats[pGuid][7477] - Parangon.Stats[pGuid][7468]);
    Parangon.setStats(player);
  end
  RegisterPlayerEvent(3, Parangon.getParangon);

  -- Server get all Parangons
  function Parangon.getAllParangons(event)
    for _, player in pairs(GetPlayersInWorld()) do
      Parangon.getParangon(event, player);
    end
  end
  RegisterServerEvent(33, Parangon.getAllParangons);


--[[
  Parangon.setParangon
    | - We save the information about the Parangons.
]]--

  -- Player save Parangon
  function Parangon.setParangon(event, player)
    local pGuid = player:GetGUIDLow();
    local pAccid = player:GetAccountId();

    local setParangonStats = CharDBExecute("UPDATE `"..Parangon.Config.dbName.."`.characters_parangon SET strenght = "..Parangon.Stats[pGuid][7464]..", agility = "..Parangon.Stats[pGuid][7471]..", stamina = "..Parangon.Stats[pGuid][7477]..", intellect = "..Parangon.Stats[pGuid][7468].." WHERE guid = "..pGuid.." AND accountid = "..pAccid..";");
    local setParangonInfo = CharDBExecute("UPDATE `"..Parangon.Config.dbName.."`.account_parangon SET level = "..Parangon.Infos[pAccid].level..", exp = "..Parangon.Infos[pAccid].exp.." WHERE accountid = "..pAccid..";");

    Parangon.Stats[pGuid] = nil;
  end
  RegisterPlayerEvent(4, Parangon.setParangon);

  -- Server save all Parangons
  function Parangon.setAllParangons(event)
    for _, player in pairs(GetPlayersInWorld()) do
      Parangon.setParangon(event, player);
    end
  end
  RegisterServerEvent(16, Parangon.setAllParangons);

--[[
  Parangon.setStatsIncrease
    | - We're going to do some checking and then we're going to award points.
]]--
  function Parangon.setStatsIncrease(player, stat, value)
    if(player:IsInCombat())then
      player:SendNotification('You can\'t do this in combat.');

    elseif(player:GetLevel() < Parangon.Config.minLevel )then
      player:SendNotification('You can\'t do this right now, you have to be level '..Parangon.Config.minLevel..' minimum.');

    else
      local pGuid = player:GetGUIDLow();
      local pAccid = player:GetAccountId();

      if ((Parangon.Infos[pAccid].points - value) < 0) then
        player:SendNotification('You don\'t have enough Parangon points left.');

      else
        Parangon.Stats[pGuid][stat] = Parangon.Stats[pGuid][stat] + value;
        Parangon.Infos[pAccid].points = ((Parangon.Infos[pAccid].level * Parangon.Config.pointsPerLevel) - Parangon.Stats[pGuid][7464] - Parangon.Stats[pGuid][7471] - Parangon.Stats[pGuid][7477] - Parangon.Stats[pGuid][7468]);
        Parangon.setStats(player);
      end
    end
  end

--[[
  Parangon.setParangonLevelUp
    | - We are going to add a level when the exp equals the exp max
]]--
  function Parangon.setParangonLevelUp(event, player)
    local pAccid = player:GetAccountId();

    if(Parangon.Infos[pAccid].exp >= (Parangon.Infos[pAccid].level * Parangon.Config.maxExp)) then

      if(Parangon.Infos[pAccid].level < Parangon.Config.maxExp) then

        Parangon.Infos[pAccid].level = Parangon.Infos[pAccid].level + 1;
        Parangon.Infos[pAccid].exp = 0;
        player:SendBroadcastMessage("Congratulations, you've just raised your level of Parangon.");
        Parangon.Infos[pAccid].points = ((Parangon.Infos[pAccid].level * Parangon.Config.pointsPerLevel) - Parangon.Stats[pGuid][7464] - Parangon.Stats[pGuid][7471] - Parangon.Stats[pGuid][7477] - Parangon.Stats[pGuid][7468]);
      end
    end
  end

--[[
  Parangon.onKillCreature | Parangon.onKillPlayer
    | - We're going to do some checking and then give the experience.
]]--

  -- Player kill creature
  function Parangon.onKillCreature(event, player, creature)
    local pLevel = player:GetLevel();
    local cLevel = creature:GetLevel();

    if ((pLevel >= Parangon.Config.minLevel) and (player:IsInGroup() == true)) then
      local group = player:GetGroup();

      for _, player in pairs (group:GetMembers()) do
        local pLevel = player:GetLevel();

        if ((pLevel - cLevel) or ((cLevel - pLevel) == 10))then
          local pAccid = player:GetAccountId();

          Parangon.Infos[pAccid].exp = Parangon.Infos[pAccid].exp + ParangonConfig.pveKill;
        end
      end
    elseif ((pLevel >= Parangon.Config.minLevel) and (player:IsInGroup() == false)) then
      if ((pLevel - cLevel) or ((cLevel - pLevel) == 10))then

        Parangon.Infos[pAccid].exp = Parangon.Infos[pAccid].exp + ParangonConfig.pveKill;
        Parangon.setParangonLevelUp(event, player);
      end
    end
  end
  RegisterPlayerEvent(7, Parangon.onKillCreature);

  -- Player kill other player
  function Parangon.onKillPlayer(event, player, victim)
    local pLevel = player:GetLevel();
    local vLevel = victim:GetLevel();

    if ((pLevel >= Parangon.Config.minLevel) and (player:IsInGroup() == true)) then
      local group = player:GetGroup();

      for _, player in pairs (group:GetMembers()) do
        local pLevel = player:GetLevel();

        if ((pLevel - vLevel) or ((vLevel - pLevel) == 10))then
          local pAccid = player:GetAccountId();

          Parangon.Infos[pAccid].exp = Parangon.Infos[pAccid].exp + ParangonConfig.pvpKill;
        end
      end
    elseif ((pLevel >= Parangon.Config.minLevel) and (player:IsInGroup() == false)) then
      if ((pLevel - vLevel) or ((vLevel - pLevel) == 10))then

        Parangon.Infos[pAccid].exp = Parangon.Infos[pAccid].exp + Parangon.Config.pvpKill;
        Parangon.setParangonLevelUp(event, player);
      end
    end
  end
  RegisterPlayerEvent(6, Parangon.onKillPlayer);


function Parangon.onGossipHello(event, player, object)
    local SMSG_NPC_TEXT_UPDATE = 384
    local MAX_GOSSIP_TEXT_OPTIONS = 8

    function Player:GossipSetText(text, textID)
        local data = CreatePacket(SMSG_NPC_TEXT_UPDATE, 100);
        data:WriteULong(textID or 0x7FFFFFFF)
        for i = 1, MAX_GOSSIP_TEXT_OPTIONS do
            data:WriteFloat(0) -- Probability
            data:WriteString(text) -- Text
            data:WriteString(text) -- Text
            data:WriteULong(0) -- language
            data:WriteULong(0) -- emote
            data:WriteULong(0) -- emote
            data:WriteULong(0) -- emote
            data:WriteULong(0) -- emote
            data:WriteULong(0) -- emote
            data:WriteULong(0) -- emote
        end
        self:SendPacket(data)
    end

    local pGuid = player:GetGUIDLow();
    local pAccid = player:GetAccountId();

    player:GossipClearMenu();
    player:GossipSetText('      '..player:GetName()..'\'s Parangon\n\nLevel : '..Parangon.Infos[pAccid].level..'\n\nExperience : '..Parangon.Infos[pAccid].exp..'\nMax Experience : '..Parangon.Config.maxExp*Parangon.Infos[pAccid].level..'\n\n'..Parangon.Config.space..Parangon.Config.space..'Your points available :\n\n'..Parangon.Config.space..Parangon.Config.space..Parangon.Config.space..Parangon.Config.space..Parangon.Config.space..'|CFFBC0000'..Parangon.Infos[pAccid].points);
    player:GossipMenuAddItem(4, '|CFF9100BC('..Parangon.Stats[pGuid][7464]..')|r |- Strenght', 1, 7464, false, '|CFFC20000/!\\ WARNINGS! /!\\\n\n|r You currently have '..Parangon.Stats[pGuid][7464]..' points of strength\nYou will add +1 to you stat.\n\nAre you sure?');
    player:GossipMenuAddItem(4, '|CFF9100BC('..Parangon.Stats[pGuid][7471]..')|r |- Agility', 1, 7471, false, '|CFFC20000/!\\ WARNINGS! /!\\\n\n|r You currently have '..Parangon.Stats[pGuid][7471]..' points of agility\nYou will add +1 to you stat.\n\nAre you sure?');
    player:GossipMenuAddItem(4, '|CFF9100BC('..Parangon.Stats[pGuid][7477]..')|r |- Stamina', 1, 7477, false, '|CFFC20000/!\\ WARNINGS! /!\\\n\n|r You currently have '..Parangon.Stats[pGuid][7477]..' points of stamina\nYou will add +1 to you stat.\n\nAre you sure?');
    player:GossipMenuAddItem(4, '|CFF9100BC('..Parangon.Stats[pGuid][7468]..')|r |- Intellect', 1, 7468, false, '|CFFC20000/!\\ WARNINGS! /!\\\n\n|r You currently have '..Parangon.Stats[pGuid][7468]..' points of intellect\nYou will add +1 to you stat.\n\nAre you sure?');
    player:GossipSendMenu(0x7FFFFFFF, player, 1);

end

function Parangon.onCommand(event, player, command)
    if(string.lower(command) == 'parangon')then
        Parangon.onGossipHello(event, player, player)
        return false;
    end
end
RegisterPlayerEvent(42, Parangon.onCommand)

function Parangon.onGossipSelect(event, player, object, sender, intid, code, menu_id)
    local pGuid = player:GetGUIDLow();
    if (intid) then
      Parangon.setStatsIncrease(player, intid, 1);
      Parangon.onGossipHello(event, player, object);
    end
end
RegisterPlayerGossipEvent(1, 2, Parangon.onGossipSelect)
