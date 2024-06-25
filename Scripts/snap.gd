class_name SnapGame
extends Node


func _ready():
	print("start Snap Game")

	var game_session := SkirmishManager.new()
	game_session.generate_players()
	game_session.match_players()


func _process(_delta):
	var _player_key : int = get_pressed_player_key()


func get_pressed_player_key() -> int:
	var possible_inputs = {"KEY_1": 0, "KEY_2": 1, "KEY_3": 2, "KEY_4": 3, "KEY_5": 4}
	var player_key = 0
	for key in possible_inputs.keys():
		if Input.is_action_just_pressed(key):
			player_key = possible_inputs[key]
	return player_key


class Card:
	var power : int
	var cost : int

	func _init(power_ : int, cost_ : int):
		power = power_
		cost = cost_

	func _to_string():
		return str(power)

class Deck:
	var card_list : Array[Card]
	var stack : Array[Card]
	var hand : Array[Card]

	var points : int

	func _init():
		stack.append(Card.new(randi_range(1, 20), 0))
		stack.append(Card.new(randi_range(1, 20), 0))
		stack.append(Card.new(randi_range(1, 20), 0))
		stack.append(Card.new(randi_range(1, 20), 0))
		stack.append(Card.new(randi_range(1, 20), 0))

	func draw(_value : int = 1):
		hand.append(stack.pop_front())

	func play(card_idx : int = 0) -> Card:
		print(" - play card idx: ", card_idx)
		var card := hand[card_idx]
		if card_idx not in range(hand.size()):
			push_error("card_idx %d is not in range for hand size %d" % [card_idx, hand.size()])
			return null
		if card.cost > points:
			push_error("card_idx %d is too expensive. Cost %d, current points %d" \
					% [card_idx, card.cost, points] )
			return null

		points -= card.cost
		return card


class Gamer:

	var ai : bool = true
	var health : int
	var deck : Deck

	var gold : int

	var current_battle : BattleManager

	func _init():
		deck = Deck.new()

	func play_card() -> Card:
		if ai:
			return deck.play(randi_range(0, deck.hand.size() - 1))

		#TODO ADD PLAYER INPUT
		return null

	func play_location_select() -> int:
		if ai:
			return randi_range(0, current_battle.locations.size() - 1)

		#TODO ADD PLAYER INPUT
		return 0


class Location:
	var sides_cards : Array = [[], []] # Array[Array[Card]]


	func get_points() -> Array[int]:
		var result : Array[int] = [0, 0]
		var idx = -1
		for side in sides_cards:
			idx += 1
			var side_sum = 0
			for card in side:
				side_sum += card.power
			result[idx] = side_sum
		return result

	func add_card(side : int, card : Card) -> void:
		sides_cards[side].append(card)


class SkirmishManager:
	var players : Array[Gamer]

	func generate_players():
		var human = Gamer.new()
		#human.ai = false
		players.append(human)
		for i in range(3):
			players.append(Gamer.new())


	func match_players():
		# random selection
		players.shuffle()
		var pairs : Array = []
		for i in range(1, players.size(), 2):
			pairs.append([i - 1, i])


		for pair in pairs:
			var new_match = BattleManager.new()
			print("start of a game, between:", pair)
			new_match.player_1 = players[pair[0]]
			new_match.player_2 = players[pair[1]]
			new_match.start_match()


	func shop():
		pass


class BattleManager:
	var max_round_number : int = 2
	var current_round : int = -1

	var player_1 : Gamer
	var player_2 : Gamer

	var locations : Array[Location]

	func display():
		print("---- board:")
		for location in locations:
			print(location.sides_cards)
		print("--------")

	func select_winner() -> int:
		if current_round != max_round_number:
			return -1 # not and end
		var winning_locations := 0
		for location in locations:
			var location_score = location.get_points()
			if location_score[0] == location_score[1]:
				continue
			if location_score[0] > location_score[1]:
				winning_locations += 1
			else:
				winning_locations -= 1

		if winning_locations == 0:
				#score deal breaker
				var players_score = [0, 0]
				for location in locations:
					var location_score = location.get_points()
					players_score[0] += location_score[0]
					players_score[1] += location_score[1]

				if players_score[0] == players_score[1]:
					return 0 # draw
				if players_score[0] > players_score[1]:
					return 1
				else:
					return 2


		if winning_locations > 0:
			return 1
		else:
			return 2




	func new_round() -> int:
		current_round += 1
		print("new round (%d):" % [current_round])
		var players := [player_1, player_2] as Array[Gamer]
		for idx in range(players.size()):
			print("player idx %d request card play:" % [idx])
			var card = players[idx].play_card()
			if card == null:
				continue
			var location_idx := players[idx].play_location_select()
			var location := locations[location_idx]
			location.add_card(idx, card)

		display() # display board state after every round


		var winner = select_winner()
		while winner == -1: # not finished
			winner = new_round()

		return winner

	func start_match() -> int:
		player_1.deck.draw(3)
		player_2.deck.draw(3)

		player_1.current_battle = self
		player_2.current_battle = self

		locations.append(Location.new())

		return new_round()




