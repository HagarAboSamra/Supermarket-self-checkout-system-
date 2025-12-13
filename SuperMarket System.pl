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

% attendant(ID, Role).
attendant(aat1, attendant).
attendant(aat2, admin).
attendant(aat3, admin).

admin_authorized(ID) :- attendant(ID, admin).

% loyalty(CardID, Points).
loyalty(card_alex, 450).
loyalty(card_sara, 1200).
loyalty(card_tom, 2500).

% Tier thresholds and percentage discount
% tier(Name, MinPoints, MaxPoints, DiscountPercent).
tier(bronze, 0, 499, 0).
tier(silver, 500, 1999, 2).
tier(gold,   2000, 999999, 5).

%pay(Method)
pay(cash).
pay(card).
pay(e-wallet).


%% Anas %%
%% Responsibility:
%% 1. Scan items and update basket & stock
%% 2. Remove items from basket and restore stock
%% 3. Ensure stock availability before any scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% stock_check/3
%% stock_check(Item, StockIn, StockOut)
%% - Verifies that the item exists in stock
%% - Decreases stock quantity by 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


stock_check(Item, StockIn, StockOut) :-
    select(stock(Item, Count), StockIn, Rest),
    Count > 0,                       % Ensure item is available
    NewCount is Count - 1,
    StockOut = [stock(Item, NewCount) | Rest].



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(scan/1) - Normal items (NOT age restricted)
%% Adds item to basket, updates total price, and decreases stock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          none,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    \+ age_restricted(Item),          % Item is NOT age restricted
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(scan/1) - Age restricted items
%% Scans item, updates stock and total,
%% but blocks the system until admin verification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          age_check_needed,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    age_restricted(Item),             % Item requires age verification
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(remove/1)
%% Removes item from basket and restores it to stock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

action(remove(Item),
    state(Basket, Total, BlockedStatus, Loyalty, StockIn, PaymentStatus),
    state(NewBasket,
          NewTotal,
          BlockedStatus,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    select(item(Item, Price, Weight), Basket, NewBasket), % Remove item from basket
    select(stock(Item, Count), StockIn, Rest),
    NewCount is Count + 1,                                % Restore stock
    StockOut = [stock(Item, NewCount) | Rest],
    NewTotal is Total - Price.

