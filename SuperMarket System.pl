%Items sold in the supermarket
% item(item,price,weight,category)

item(milk,20,1000,food).
item(bread,15,400,food).
item(apple,5,variable,fruits).
item(banana,4,variable,fruits).
item(chips,10,150, snack).
item(chocolate,12,120,snack).
item(soap,18,250,cleaning).
item(wine,150,750,alcohol).
item(beer,45,330, alcohol).
item(vodka,220,500, alcohol).

%Age restricted items
age_restricted(wine).
age_restricted(beer).
age_restricted(vodka).


stock(milk,5).
stock(bread,7).
stock(apple,30).
stock(banana,25).
stock(chips,10).
stock(chocolate,6).
stock(soap,8).
stock(wine,3).
stock(beer,12).
stock(vodka,4).


%taxes on sold stocks
tax_rate(food,0.05).
tax_rate(fruits,0.00).
tax_rate(snack,0.10).
tax_rate(cleaning,0.14).
tax_rate(alcohol,0.20).

% loyalty(CardID, Points).
loyalty(card_alex, 450).
loyalty(card_sara, 1200).
loyalty(card_tom, 2500).

% Tier thresholds and percentage discount
% tier(Name, MinPoints, MaxPoints, DiscountPercent).
tier(bronze, 0, 499, 0).
tier(silver, 500, 1999, 2).
tier(gold,   2000, 999999, 5).
