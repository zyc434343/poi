{relative, join} = require 'path-extra'
{_, $, $$, React, ReactBootstrap, ROOT, toggleModal} = window
{$ships, $shipTypes, _ships} = window
{Button, ButtonGroup} = ReactBootstrap

{PaneBody} = require './parts'

inBattle = [false, false, false, false]
goback = {}
combined = false

getStyle = (state) ->
  if state in [0..5]
    # 0: Cond >= 40, Supplied, Repaired, In port
    # 1: 20 <= Cond < 40, or not supplied, or medium damage
    # 2: Cond < 20, or heavy damage
    # 3: Repairing
    # 4: In mission
    # 5: In map
    return ['success', 'warning', 'danger', 'info', 'primary', 'default'][state]
  else
    return 'default'
getDeckState = (deck) ->
  state = 0
  {$ships, _ships} = window
  # In mission
  if inBattle[deck.api_id - 1]
    state = Math.max(state, 5)
  if deck.api_mission[0] > 0
    state = Math.max(state, 4)
  for shipId in deck.api_ship
    continue if shipId == -1
    ship = _ships[shipId]
    shipInfo = $ships[ship.api_ship_id]
    # Cond < 20 or medium damage
    if ship.api_cond < 20 || ship.api_nowhp / ship.api_maxhp < 0.25
      state = Math.max(state, 2)
    # Cond < 40 or heavy damage
    else if ship.api_cond < 40 || ship.api_nowhp / ship.api_maxhp < 0.5
      state = Math.max(state, 1)
    # Not supplied
    if ship.api_fuel / shipInfo.api_fuel_max < 0.99 || ship.api_bull / shipInfo.api_bull_max < 0.99
      state = Math.max(state, 1)
    # Repairing
    if shipId in window._ndocks
      state = Math.max(state, 3)
  state

module.exports =
  name: 'ShipView'
  priority: 0.1
  displayName: <span><FontAwesome key={0} name='server' /> 舰队</span>
  description: '舰队展示页面，展示舰队详情信息'
  reactClass: React.createClass
    getInitialState: ->
      names: ['第1艦隊', '第2艦隊', '第3艦隊', '第4艦隊']
      states: [-1, -1, -1, -1]
      decks: []
      activeDeck: 0
      dataVersion: 0
    showDataVersion: 0
    shouldComponentUpdate: (nextProps, nextState)->
      # if ship-pane is visibile and dataVersion is changed, this pane should update!
      if nextProps.selectedKey is @props.index and nextState.dataVersion isnt @showDataVersion
        @showDataVersion = nextState.dataVersion
        return true
      if @state.decks.length is 0 and nextState.decks.length isnt 0
        return true
      false
    handleClick: (idx) ->
      if idx isnt @state.activeDeck
        @setState
          activeDeck: idx
          dataVersion: @state.dataVersion + 1
    handleResponse: (e) ->
      {method, path, body, postBody} = e.detail
      {names} = @state
      flag = true
      switch path
        when '/kcsapi/api_port/port'
          names = body.api_deck_port.map (e) -> e.api_name
          inBattle = [false, false, false, false]
          goback = {}
          combined = body.api_combined_flag? && body.api_combined_flag > 0
        when '/kcsapi/api_req_hensei/change', '/kcsapi/api_req_hokyu/charge', '/kcsapi/api_get_member/deck', '/kcsapi/api_get_member/ship_deck', '/kcsapi/api_get_member/ship2', '/kcsapi/api_get_member/ship3', '/kcsapi/api_req_kousyou/destroyship', '/kcsapi/api_req_kaisou/powerup', '/kcsapi/api_req_nyukyo/start', '/kcsapi/api_req_nyukyo/speedchange'
          true
        # FCF
        when '/kcsapi/api_req_combined_battle/goback_port'
          {decks, _ships} = @state
          damagedShip = -1
          if damagedShip == -1
            for shipId, idx in decks[0].api_ship
              continue if shipId == -1 || idx == 0
              ship = _ships[shipId]
              if ship.api_nowhp / ship.api_maxhp < 0.250001 and !goback[shipId]
                damagedShip = shipId
                break
          if damagedShip == -1
            for shipId, idx in decks[1].api_ship
              continue if shipId == -1 || idx == 0
              ship = _ships[shipId]
              if ship.api_nowhp / ship.api_maxhp < 0.250001 and !goback[shipId]
                damagedShip = shipId
                break
          if damagedShip != -1
            gobackShip = -1
            for shipId, idx in decks[1].api_ship
              continue if shipId == -1 || idx == 0
              ship = _ships[shipId]
              if ship.api_stype == 2 and ship.api_nowhp / ship.api_maxhp > 0.750001 and !goback[shipId]
                gobackShip = shipId
                break
            if gobackShip != -1
              console.log "退避：#{_ships[damagedShip].api_name} 护卫：#{_ships[gobackShip].api_name}"
              goback[damagedShip] = goback[gobackShip] = true
        when '/kcsapi/api_req_map/start', '/kcsapi/api_req_map/next'
          if path == '/kcsapi/api_req_map/start'
            if combined
              deckId = 0
              inBattle[0] = inBattle[1] = true
            else
              deckId = parseInt(postBody.api_deck_id) - 1
              inBattle[deckId] = true
          {decks, states} = @state
          {_ships, _slotitems} = window
          for deckId in [0..3]
            continue unless inBattle[deckId]
            deck = decks[deckId]
            for shipId in deck.api_ship
              continue if shipId == -1
              ship = _ships[shipId]
              if ship.api_nowhp / ship.api_maxhp < 0.250001 and !goback[shipId]
                # 应急修理要员/女神
                safe = false
                for slotId in ship.api_slot
                  continue if slotId == -1
                  safe = true if _slotitems[slotId].api_type[3] is 14
                if !safe
                  toggleModal '注意！', "Lv. #{ship.api_lv} - #{ship.api_name} 大破，可能有击沉风险！"
        else
          flag = false
      return unless flag
      decks = window._decks
      states = decks.map (deck) ->
        getDeckState deck
      @setState
        names: names
        decks: decks
        states: states
        dataVersion: @state.dataVersion + 1
    componentDidMount: ->
      window.addEventListener 'game.response', @handleResponse
    componentWillUnmount: ->
      window.removeEventListener 'game.response', @handleResponse
      @interval = clearInterval @interval if @interval?
    render: ->
      <div>
        <link rel="stylesheet" href={join(relative(ROOT, __dirname), 'assets', 'ship.css')} />
        <ButtonGroup>
        {
          for i in [0..3]
            <Button key={i} bsSize="small"
                            bsStyle={getStyle @state.states[i]}
                            onClick={@handleClick.bind(this, i)}
                            className={if @state.activeDeck == i then 'active' else ''}>
              {@state.names[i]}
            </Button>
        }
        </ButtonGroup>
        {
          for deck, i in @state.decks
            <div className="ship-deck" className={if @state.activeDeck is i then 'show' else 'hidden'} key={i}>
              <PaneBody
                key={i}
                deckIndex={i}
                deck={@state.decks[i]}
                activeDeck={@state.activeDeck}
                deckName={@state.names[i]}
              />
            </div>
        }
      </div>
