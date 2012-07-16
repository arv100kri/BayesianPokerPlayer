%% Decision Making
%%
%% INPUT: a structure "info" containing the following field
%%        stage, pot, cur_pos, cur_pot, first_pos, board card,
%%        hole_card, active, paid, history, su_info, oppo_model
%% OUTPUT: an integer from 1 to 3 indicating:
%%         1: CALL or CHECK
%%         2: BET or RAISE
%%         3. FOLD

%% We provide some auxiliary probability tables, see section 3.4 
%% in the write-up. If you use BNT by Kevin Murphy, please check
%% sample BNT code student_BNT.m in T-Square to see how to use it.
%%
%% Some zero entrie do not really mean zero probability, instead
%% they mean states we do not care about because they can not
%% contribute to any effective hand category in the showdown

%% Table 1: Prior probability of final categories given 7 cards

%%  Busted          0.1728
%%  One Pair        0.438
%%  Two Pair        0.2352
%%  3 of a Kind     0.0483
%%  Straight        0.048
%%  Flush           0.0299
%%  Full House      0.0255
%%  4 of a Kind     0.0019
%%  Straight Flush	0.0004

%% Table 2: Straight and Flush CPT from flop (given two draws)

%%                  SF      Flush	Straight
%%	SFO3            0.0028	0.0389	0.0416
%%	SFO4            0.0842	0.2784	0.2414
%%	SFI4            0.0426	0.3145	0.1249
%%	F3              0       0.0416	0
%%	F4              0       0.3497	0
%%	SO3             0       0       0.0444
%%	SO4             0       0       0.3145
%%	SI4             0       0       0.1647
%%	SFO3 & F4       0.0028	0.3469	0.0416
%%	SFO3 & SI4      0.0028	0.0389	0.1360
%%	SFO3 & SO4      0.0028	0.0389	0.2784
%%	SI4 & F3        0       0.0416	0.1647
%%	SI4 & F4        0       0.3497	0.1249
%%	SO3 & F3        0    	0.0416	0.0416
%%	SO3 & F4        0    	0.3497	0.0250
%%	SO4 & F3        0    	0.0416	0.2756
%%	SO4 & F4        0    	0.3497	0.2414

%% Table 3: N of a Kind CPT from flop (given two draws)

%%              K4      K3K2	K3      K2K2	K2	Junk
%%	K3K2	0.0435	0.9565  0       0   	0	0
%%	K3      0.0426	0.1249	0.8325  0       0	0
%%	K2K2	0.0019	0.1619	0.0000	0.8362  0	0
%%	K2      0.0009	0.0250	0.0666	0.3000	0.6075	0
%%	Junk	0.0000	0.0000	0.0139	0.0832	0.4440	0.4589

%% Table 4: Straight and Flush CPT from turn (given one draw)

%%              SF      Flush	Straight
%%	SFO4	0.0435	0.1522	0.1739
%%	SFI4	0.0217	0.1739	0.0870
%%	F4      0       0.1957	0
%%	SO4     0       0       0.1739
%%	SI4     0       0       0.0870

%% Table 5: N of a Kind CPT from turn (given one draw)

%%              K4          K3K2    K3      K2K2	K2	Junk
%%	K3K2	0.0217      0.9783  0       0      	0	0
%%	K3      0.0217      0.1960  0.7823  0		0	0
%%	K2K2	0.0000      0.0870  0       0.913       0	0
%%	K2      0.0000      0       0.0435  0.2609	0.6956	0
%%	Junk	0.0000      0       0       0    	0.3910	0.609


function decision = MakeDecision(info)
    if (info.stage == 0) 
        decision = MakeDecisionPreFlop(info);
    else
        decision = MakeDecisionPostFlop(info);
    end 
end

function decision = MakeDecisionPreFlop(info)
    %% distribution = [];
    %% ----- FILL IN THE MISSING CODE ----- %%
    %% win_prob = PredictWin(distribution);
    %% ----- FILL IN THE MISSING CODE ----- %%
    
    preflop_category = preflop_cardtype(info.hole_card(1), info.hole_card(2));
    card1 = floor(info.hole_card(1)/4)+2;
    card2 = floor(info.hole_card(2)/4)+2;
    
    %% check if we have a pair - N of a kind
    is_pair = false;
    if card1 == card2
        is_pair = true;
    end
    
    %% get the distance between the 2 cards
    distance = abs(card1 - card2);
    % handle special case of ace, which can be used at top and bottom of hand
    if card1 == 14
        distance = min(distance, card2 - 1);
    elseif card2 == 14
        distance = min(distance, card1 - 1);
    end
    
    %% check if they are sequential - Straight
    is_sequential = false;
    if distance == 1
        is_sequential = true;
    end
    
    %% check if they are of same suit - flush
    is_same_suit = false;
    if mod(info.hole_card(1), 4) == mod(info.hole_card(2), 2)
        is_same_suit = true;
    end
    
    is_nines_or_better_wired = false;
    if is_pair && (card1 >= 9)
        is_nines_or_better_wired = true;
    end
    
    is_jacks_or_better_split = false;
    if not(is_pair) && (card1 >= 11 || card2 >= 11)
        is_jacks_or_better_split = true;
    end
    
    %% TODO: incorporate agent bluff
    
    %% incorporate betting history for this round    
    %% incorporate playing style of the opponents: loose/tight, aggr/passive
    %% Eg: number of tight players who have called or raised earlier is an indicator of the table strength
    
    N = size(info.active, 2);
    oppo_model = cell2mat(info.oppo);
    
    stats = GetStatisticsForCurrentStage(info.cur_pos, info.first_pos, N, oppo_model, info.paid, info.stage);
    numTightsWhoHaveCalled = stats(1); numTightsWhoHaveRaised = stats(2);
    numTightsWhoHaveCheckRaised = stats(3); numTightsWhoHaveReRaised = stats(4);
    
    CALL = 1; RAISE = 2; FOLD = 3;
    decision = FOLD;
    if preflop_category <= 3 || is_nines_or_better_wired || is_jacks_or_better_split || is_same_suit || is_sequential
       decision = RAISE;
    elseif preflop_category < 5 || distance <= 3 %% case of just pair, but not nines or better is handled here
        decision = CALL;
    end
    
    if decision < FOLD && ((preflop_category > 2  && numTightsWhoHaveRaised >= 1) || (preflop_category > 4 && numTightsWhoHaveCalled >= 1) || numTightsWhoHaveCheckRaised >= 0.5 || numTightsWhoHaveReRaised >= 0.5) 
        if decision == CALL
            decision = FOLD;
        else
            decision = CALL;
        end
    end    

    if decision == FOLD
      %venture into the other three quadrants of TightPassive(0.15), LoosePassive(0.40) and LooseAggressive(0.45) with non-zero probability
      randomDouble = rand(1);
      if randomDouble >= 0.55
        decision = CALL;
        if randomDouble >= 0.775
          decision = RAISE;
        end
      elseif randomDouble >= 0.15 && randomDouble >= 0.25
        decision = CALL;
      end %fold all other cases
    end

    
    %% The following is just a sample of randomly generating different
    %% decisions. Please comment them after you finish your part.
    %% num = floor(rand(1)*100);
    %%if (num <= 60)
    %%    decision = 1;
    %%elseif (num <= 90)
    %%   decision = 2;
    %%else
    %%    decision = 3;
    %%end    
end

function stats = GetStatisticsForCurrentStage(cur_pos, first_pos, N, oppo_model, paid, stage)
    numTightsWhoHaveCalled = 0.0; numTightsWhoHaveRaised = 0.0;
    numTightsWhoHaveCheckRaised = 0.0; numTightsWhoHaveReRaised = 0.0;
    
    NUMCALLSINCURRENTSTAGE = 1; NUMRAISESINCURRENTSTAGE = 2; NUMCHECKRAISESINCURRENTSTAGE = 3; NUMRERAISESINCURRENTSTAGE = 4;
    TIGHTAGGRESSIVE = 2; TIGHTPASSIVE = 4;

    SBU = 10;
    BettingAmount = SBU;
    
    if stage >= 3
        BettingAmount = 2*SBU;
    end


    % the first iteration has zero size for oppo_model
    if size(oppo_model,1) > 0
        
        for player = 1:N
           if player ~= cur_pos
                featureVector = zeros(1, 4);
                if paid(player) >= BettingAmount
                    featureVector(NUMCALLSINCURRENTSTAGE) = featureVector(NUMCALLSINCURRENTSTAGE) + 1;
                end

                if paid(player) > BettingAmount
                    featureVector(NUMRAISESINCURRENTSTAGE) = featureVector(NUMRAISESINCURRENTSTAGE) + (paid(player) - BettingAmount)/BettingAmount;
                end

                if paid(player) >= 2*BettingAmount %one call followed by one raise
                    featureVector(NUMCHECKRAISESINCURRENTSTAGE) = featureVector(NUMCHECKRAISESINCURRENTSTAGE) + 1;
                end

                if paid(player) > 2*BettingAmount %N raises followed by another raise
                    featureVector(NUMRERAISESINCURRENTSTAGE) = featureVector(NUMRERAISESINCURRENTSTAGE) + (paid(player) - 2*BettingAmount)/BettingAmount;
                end
               
               positionRV = GetPosition(player, first_pos, N);
               % add the proboftight*numcalled
               % add the proboftight*numRaised
               if positionRV == 1 || positionRV == 2
                    numTightsWhoHaveCalled = numTightsWhoHaveCalled + oppo_model(player, 4*(positionRV -1) + TIGHTAGGRESSIVE)*featureVector(NUMCALLSINCURRENTSTAGE) + oppo_model(player, 4*(positionRV -1) + TIGHTPASSIVE)*featureVector(NUMCALLSINCURRENTSTAGE);
                    numTightsWhoHaveRaised = numTightsWhoHaveRaised + oppo_model(player, 4*(positionRV -1) + TIGHTAGGRESSIVE)*featureVector(NUMRAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRV -1) + TIGHTPASSIVE)*featureVector(NUMRAISESINCURRENTSTAGE);
                    
                    numTightsWhoHaveCheckRaised = numTightsWhoHaveCheckRaised + oppo_model(player, 4*(positionRV -1) + TIGHTAGGRESSIVE)*featureVector(NUMCHECKRAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRV -1) + TIGHTPASSIVE)*featureVector(NUMCHECKRAISESINCURRENTSTAGE);
                    numTightsWhoHaveReRaised = numTightsWhoHaveReRaised + oppo_model(player, 4*(positionRV -1) + TIGHTAGGRESSIVE)*featureVector(NUMRERAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRV -1) + TIGHTPASSIVE)*featureVector(NUMRERAISESINCURRENTSTAGE);
                    
               else
                   for positionRVDummy = 1:2
                        numTightsWhoHaveCalled = numTightsWhoHaveCalled + 0.5*(oppo_model(player, 4*(positionRVDummy -1) + TIGHTAGGRESSIVE)*featureVector(NUMCALLSINCURRENTSTAGE) + oppo_model(player, 4*(positionRVDummy -1) + TIGHTPASSIVE)*featureVector(NUMCALLSINCURRENTSTAGE));
                        numTightsWhoHaveRaised = numTightsWhoHaveRaised + 0.5*(oppo_model(player, 4*(positionRVDummy -1) + TIGHTAGGRESSIVE)*featureVector(NUMRAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRVDummy -1) + TIGHTPASSIVE)*featureVector(NUMRAISESINCURRENTSTAGE));
                        
                        numTightsWhoHaveCheckRaised = numTightsWhoHaveCheckRaised + 0.5*(oppo_model(player, 4*(positionRVDummy -1) + TIGHTAGGRESSIVE)*featureVector(NUMCHECKRAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRVDummy -1) + TIGHTPASSIVE)*featureVector(NUMCHECKRAISESINCURRENTSTAGE));
                        numTightsWhoHaveReRaised = numTightsWhoHaveReRaised + 0.5*(oppo_model(player, 4*(positionRVDummy -1) + TIGHTAGGRESSIVE)*featureVector(NUMRERAISESINCURRENTSTAGE) + oppo_model(player, 4*(positionRVDummy -1) + TIGHTPASSIVE)*featureVector(NUMRERAISESINCURRENTSTAGE));
                   end
               end
               
           end
        end
    
    end

    stats = [numTightsWhoHaveCalled numTightsWhoHaveRaised numTightsWhoHaveCheckRaised numTightsWhoHaveReRaised];
end

%% Compute final hand prob vector given the hand strength prob vector
function finalHandProbVector = GetFinalHandProbabilities(handStrengthProbVector)
    % 1 - SF, 2 - K4 - Category1
    % 3 - K3K2, 4 - F, 5 - S,  - Category2
    % 6 - K3, 7 - K2K2, - Category3
    % 8 - K2, 9 - Junk - Category4
    
    finalHandProbVector = zeros(1, 9);
    finalHandProbVector(1) = handStrengthProbVector(1)/2; 
    finalHandProbVector(2) = handStrengthProbVector(1)/2;
    
    finalHandProbVector(3) = handStrengthProbVector(2)/3;
    finalHandProbVector(4) = handStrengthProbVector(2)/3;
    finalHandProbVector(5) = handStrengthProbVector(2)/3;
    
    finalHandProbVector(6) = handStrengthProbVector(3)/2;
    finalHandProbVector(7) = handStrengthProbVector(3)/2;
    
    finalHandProbVector(8) = handStrengthProbVector(4)/2;
    finalHandProbVector(9) = handStrengthProbVector(4)/2;
    
    % ensure this vector is normalized
    if sum(finalHandProbVector) > 0
        finalHandProbVector = finalHandProbVector / sum(finalHandProbVector);
    end
end

%% This is the function that represents the CPT of P(Strength | Style, BettingBehaviour)
function stylenbet2strengthmat = GetStyleAndBetMappedToStrengthMatrix()
    % category 1 is strongest and category 4 is weakest
    
    LA = 1; TA = 2; LP = 3; TP = 4;
    NUMCATEGORIES = 4; NUMSTYLES = 4;
    NUMBETTINGFEATURES = 8;
    stylenbet2strengthmat = zeros(NUMSTYLES, NUMBETTINGFEATURES, NUMCATEGORIES);
    
    %LA: CheckPreflop:1/2/3/4, RaisePreflop:1/2/3/4, CheckRaisePreflop:1/2/3, ReRaisePreFlop:1/2/3, Check: 1/2/3/4, Raise:1/2/3/4, CheckRaise: 1/2, Reraise: 1/2
    for feature = [1 2 5 6]
        for category = 1:NUMCATEGORIES
        stylenbet2strengthmat(LA, feature, category) = 0.25;
        end
    end
    
    for feature = 3:4
      for category = 1:NUMCATEGORIES-1
        stylenbet2strengthmat(LA, feature, category) = 1/3;
      end
    end
    
    for feature = 7:8
      for category = 1:2
        stylenbet2strengthmat(LA, feature, category) = 1/2;
      end
    end
    
    
    %TA: CheckPreflop:1/2/3, RaisePreflop:1/2, CheckRaisePreflop:1/2, ReRaisePreFlop:1, Check: 1/2/3, Raise: 1/2, CheckRaise: 1/2, Reraise: 1
    for feature = [1 5]
      for category = 1:NUMCATEGORIES - 1
        stylenbet2strengthmat(TA, feature, category) = 1/3;
      end
    end
    
    for feature = [2 3 6 7]
      for category = 1:2
        stylenbet2strengthmat(TA, feature, category) =1/2;
      end
    end
    
    for feature = [4 8]
      stylenbet2strengthmat(TA, feature, 1) = 1;
    end
    
    %LP: CheckPreflop:1/2/3/4, RaisePreflop:1/2/3, CheckRaisePreflop:1/2, ReRaisePreFlop:1/2, Check: 1/2/3/4, Raise: 1/2/3, CheckRaise: 1/2, Reraise: 1
    for feature = [1 5]
      for category = 1:NUMCATEGORIES
        stylenbet2strengthmat(LP, feature, category) = 0.25;
      end
    end
    
    for feature = [2 6]
      for category = 1:NUMCATEGORIES - 1
        stylenbet2strengthmat(LP, feature, category) = 1/3;
      end
    end
    
    for feature = [3 4 7]
      for category = 1:2
        stylenbet2strengthmat(LP, feature, category) = 1/2;
      end
    end
    
    stylenbet2strengthmat(LP, 8, 1) = 1;
    
    %TP: CheckPreflop:1/2, RaisePreflop:1, CheckRaisePreflop:1/2, ReRaisePreFlop:1, Check:1/2/3, Raise:1/2, CheckRaise: 1/2, Reraise: 1
    for feature = [1 3 6 7]
      for category = 1:2
        stylenbet2strengthmat(TP, 1, category) = 0.5;
      end
    end
    
    for feature = [2 4 8]
      stylenbet2strengthmat(TP, feature, 1) = 1;
    end
    
    for category = 1:NUMCATEGORIES-1
        stylenbet2strengthmat(TP, 5, category) = 1/3;
    end
    
end

%% Given the betting behaviour features for a particular player, get this betting behaviour vector
% WARNING: This vector can be unnormalized. Ensure that the vector i compute using this vector is normalized
function behaviourVector = GetBettingBehaviourVector(betting_behaviour)
    NUMBETTINGFEATURES = 8;
    behaviourVector = zeros(1, NUMBETTINGFEATURES);
    PERCENT_CALL_PREFLOP = 1; PERCENT_RAISE_PREFLOP = 2;
    
    if betting_behaviour(PERCENT_CALL_PREFLOP) + betting_behaviour(PERCENT_RAISE_PREFLOP) > 0
      behaviourVector(PERCENT_CALL_PREFLOP) = betting_behaviour(PERCENT_CALL_PREFLOP) /(betting_behaviour(PERCENT_CALL_PREFLOP) + betting_behaviour(PERCENT_RAISE_PREFLOP));
      behaviourVector(PERCENT_RAISE_PREFLOP) = betting_behaviour(PERCENT_RAISE_PREFLOP) /(betting_behaviour(PERCENT_CALL_PREFLOP) + betting_behaviour(PERCENT_RAISE_PREFLOP));
    end
    
    PERCENT_CHECKRAISE_PREFLOP = 3; PERCENT_RERAISE_PREFLOP = 4;
    if betting_behaviour(PERCENT_RAISE_PREFLOP) > 0
      behaviourVector(PERCENT_CHECKRAISE_PREFLOP) = betting_behaviour(PERCENT_CHECKRAISE_PREFLOP) / betting_behaviour(PERCENT_RAISE_PREFLOP);
      behaviourVector(PERCENT_RERAISE_PREFLOP) = betting_behaviour(PERCENT_RERAISE_PREFLOP) / betting_behaviour(PERCENT_RAISE_PREFLOP);
    end

    PERCENT_TOTAL_CALL = 5; PERCENT_TOTAL_RAISE = 6;
    if betting_behaviour(PERCENT_TOTAL_CALL) + betting_behaviour(PERCENT_TOTAL_RAISE) > 0
      behaviourVector(PERCENT_TOTAL_CALL) = betting_behaviour(PERCENT_TOTAL_CALL) /(betting_behaviour(PERCENT_TOTAL_CALL) + betting_behaviour(PERCENT_TOTAL_RAISE));
      behaviourVector(PERCENT_TOTAL_RAISE) = betting_behaviour(PERCENT_TOTAL_RAISE) /(betting_behaviour(PERCENT_TOTAL_CALL) + betting_behaviour(PERCENT_TOTAL_RAISE));
    end

    PERCENT_TOTAL_CHECKRAISE = 7; PERCENT_TOTAL_RERAISE = 8;
    if betting_behaviour(PERCENT_TOTAL_RAISE) > 0
      behaviourVector(PERCENT_TOTAL_CHECKRAISE) = betting_behaviour(PERCENT_TOTAL_CHECKRAISE) / betting_behaviour(PERCENT_TOTAL_RAISE);
      behaviourVector(PERCENT_TOTAL_RERAISE) = betting_behaviour(PERCENT_TOTAL_RERAISE) / betting_behaviour(PERCENT_TOTAL_RAISE);
    end

end

%% Given the prob for the position based playing style and deterministic betting_behaviour, get the hand strength
function handStrengthProbVector = GetHandStrength(stylenbet2strengthmat, playingStyleVector, behaviourVector)
    NUMBETTINGFEATURES = 8; NUMCATEGORIES = 4; NUMSTYLES = 4;
    handStrengthProbVector = zeros(1, NUMCATEGORIES);
    
    for handStrength = 1:NUMCATEGORIES
      for playingStyle = 1:NUMSTYLES
          for behaviour = 1:NUMBETTINGFEATURES
              handStrengthProbVector(handStrength) = handStrengthProbVector(handStrength) + stylenbet2strengthmat(playingStyle, behaviour, handStrength) * playingStyleVector(playingStyle) * behaviourVector(behaviour);
          end
      end
    end

    % there is a chance that the above sum might produce probabilities greater than 1. Hence, renormalize the handstrength vector
    % this is because the behaviour vector is not normalized
    if sum(handStrengthProbVector) > 0
      handStrengthProbVector = handStrengthProbVector / sum(handStrengthProbVector);
    end
    
end

%% Get early/late position of a player
% I have replaced numActive with N
function positionRV = GetPosition(cur_pos, first_pos, N)
    NULLPOS = 0; EARLYPOS = 1; LATEPOS = 2;
    positionRV = NULLPOS;
    
    actual_pos = mod(cur_pos - first_pos + N, N) + 1;
    if actual_pos <= floor(N / 3)
        positionRV = EARLYPOS;
    elseif actual_pos >= floor(2 * N / 3)
        positionRV = LATEPOS;
    end 
    
end

%% Get Hole card distribution given the FinalHand Probabilities and the bnet for (CH, SG) -> FH
function [handProbVector, suitProbVector] = GetHoleCardDistribution(finalHandProbVector, bnetS, bnetK, sgValue, board_card)
    TOTAL_HOLECARD_DIFF_VALUES = 13 * 12 / 2; %= 78;
    TOTAL_HOLECARD_SAME_VALUES = 13;
    TOTAL_HANDS = TOTAL_HOLECARD_DIFF_VALUES + TOTAL_HOLECARD_SAME_VALUES;
    TOTAL_SUITS = 4 * 3 / 2;
    
    % The evidence given is: current stage (sgValue), board cards(board_card)
    handProbVector = zeros(1, TOTAL_HANDS); suitProbVector = zeros(1, TOTAL_SUITS);
    
    % We know the probabilities of seeing each of the final hands.
    % Assume we see each of the final hand and 
    % compute the prior over hand vector and suit vector and 
    % weigh it by the prob of seeing this final hand

    % This allows me to loop over the number of final hands and still use the values used by bnetS and bnetK
    FinalHandToActualHandMap = [2 3 4 6 5 4 3 2 1];
    NumNodesInBNet = 3; SC = 1; KC = 1; SG = 2;
    
    for finalHand = 1:9
        handsuitVector = zeros(1, TOTAL_HANDS * TOTAL_SUITS);
        currentHandVector = zeros(1, TOTAL_HANDS);
        currentSuitVector = zeros(1, TOTAL_SUITS);
        
        NSamples = 50;
        for samples = 1:NSamples
        %for hand = 1:TOTAL_HANDS
            %for suit = 1:TOTAL_SUITS
                hand = randi(TOTAL_HANDS);
                suit = randi(TOTAL_SUITS);
                % Get the current values for the hand
                handV = [hand - TOTAL_HOLECARD_DIFF_VALUES hand - TOTAL_HOLECARD_DIFF_VALUES];
                if hand < 78
                    handV(1) = hand / 6;
                    handV(2) = mod(hand, 6);
                end

                % Get the current values for the suit
                suitV = [suit/2 mod(suit, 2)];
                
                %sample each of the four combinations possible(h1s1h2s1, h1s2h2s1, h1s1h2s2, h1s2h2s2) and weigh it equally
                for combo = 1:4
                    % Form the current hole card combination
                    holecard = [handV(1)*suitV(2-mod(combo,2)) handV(2)*suitV(ceil(combo/2))];
                        
                    if finalHand <= 3 %SF hand category                        
                        currentHand = sftype([holecard board_card]) + 1;
                        data_case = cell(NumNodesInBNet,1);
                        clamped = zeros(NumNodesInBNet, 1);
                        clamped(SC, 1) = 1;
                        clamped(SG, 1) = 1;
                        data_case(:,1) = {currentHand sgValue FinalHandToActualHandMap(finalHand)};
                        handsuitVector(hand*suit) = handsuitVector(hand*suit) + 0.25*exp(log_lik_complete(bnetS, data_case, clamped));
                        
                    else %NofaKind hand category
                        currentHand = cardtype([holecard board_card]) + 1;
                        data_case = cell(NumNodesInBNet,1);
                        clamped = zeros(NumNodesInBNet, 1);
                        clamped(KC, 1) = 1;
                        clamped(SG, 1) = 1;
                        data_case(:,1) = {currentHand sgValue FinalHandToActualHandMap(finalHand)};
                        handsuitVector(hand*suit) = handsuitVector(hand*suit) + 0.25*exp(log_lik_complete(bnetK, data_case, clamped));
                        
                    end
                end
            %end
        %end
        end
        
        % compute the posterior probabilities by using the formula for likelihood weighted sampling
        if sum(handsuitVector) > 0
            handsuitVector = handsuitVector / sum(handsuitVector);
        end
        
        %compute the probability over the hand vector by summing across the suit combinations possible
        for hand = 1:TOTAL_HANDS
            for suit = 1:TOTAL_SUITS
                currentHandVector(hand) =  currentHandVector(hand) + handsuitVector(hand*suit);
            end
        end
        
        %ensure this is normalized
        if sum(currentHandVector) > 0
            currentHandVector = currentHandVector / sum(currentHandVector);
        end
        
        %compute the probability over the suit vector by summing across the hand combinations possible
        for suit = 1:TOTAL_SUITS
            for hand = 1:TOTAL_HANDS
                currentSuitVector(suit) =  currentSuitVector(suit) + handsuitVector(hand*suit);
            end
        end
        
        %ensure this is normalized
        if sum(currentSuitVector) > 0
            currentSuitVector = currentSuitVector / sum(currentSuitVector);
        end
        
        %add them to the final hole card hand prob vector and suit vectors by weighting with the probabilty of seeing this final hand
        handProbVector = handProbVector + currentHandVector * finalHandProbVector(finalHand);
        suitProbVector = suitProbVector + currentSuitVector * finalHandProbVector(finalHand);
    end
    
end

%% PredictHoleCards should return the posterior probabilities of each opponent forming each of the Sf and Kf final hands
% oppo_dis should not contain cases of junk or no pair
% oppo_dis contains info for all players including a zero vector for the agent
function oppo_dis = predictholecards(info, bnetS, bnetK)
  % Get the position vector for all the players
  N = size(info.active, 2);
  %numActive = sum(info.active);
  EARLYPOS = 1; LATEPOS = 2;
  numNonJunkFinalCards = 3 + 5;
  oppo_dis = zeros(N, numNonJunkFinalCards);
  
  stylenbet2strengthmat = GetStyleAndBetMappedToStrengthMatrix();
  oppo_model = cell2mat(info.oppo);
  
  % Compute the hole cards for each player and output the posterior
  % probability for the final hand in the corresponding row of oppo_dis
  for player = 1:N
      
      if player == info.cur_pos
          continue;
      end
      
      % Get the position (EARLY/LATE/NULL) for this player
      position = GetPosition(player, info.first_pos, N);
      
      % Given the position, compute the playing style for this player from the oppo_model we have built
      playingStyleVector = ones(1, 4)/4;
      if size(oppo_model, 1) > 0
          
          if position == EARLYPOS && sum(oppo_model(player, 1:4)) > 0
              playingStyleVector = oppo_model(player, 1:4);
          elseif position == LATEPOS && sum(oppo_model(player, 5:8)) > 0
              playingStyleVector = oppo_model(player, 5:8);
          elseif sum(oppo_model(player, 1:4)) > 0 && sum(oppo_model(player, 5:8)) > 0
              playingStyleVector = oppo_model(player, 1:4)/2 + oppo_model(player, 5:8)/2;
              % assume early and late with 50% prob
          end
      
      end
      
      % TODO: Get the bluff probability from the oppo_model as well      
      
      % Compute the behaviour vector for this player
      behaviourVector = GetBettingBehaviourVector(info.su_info(player, :));

      % Given the prob for the position based playing style and deterministic betting_behaviour, get the hand strength
      handStrengthProbVector = GetHandStrength(stylenbet2strengthmat, playingStyleVector, behaviourVector);

      % Given the handStrengthVector, get the final hand prob vector
      finalHandProbVector = GetFinalHandProbabilities(handStrengthProbVector);
      oppo_dis(player,:) = finalHandProbVector(1:8); %ignore the junk card for predict win
      
      % Given the final hand and the bnet for (CH, SG)->FH, 
      % compute the probability of seeing the hole cards given the board cards and the current stage of the game
      [handProbVector, suitProbVector] = GetHoleCardDistribution(finalHandProbVector, bnetS, bnetK, info.stage, info.board_card);
  end
  
  
  
  
end


function decision = MakeDecisionPostFlop(info)
    %priorProbS = [0.0004 0.0299 0.048];
    %priorProbK = [0.0019 0.0255 0.0483 0.2352 0.438 0.1728];
    SBU = 10;
    %% distribution = [];
    [bnetS, bnetK] = create_bayesnet();
    
    %% Get the agent's current distribution
    [scValue scHighCard] = sftype([info.hole_card info.board_card]);
    %adding 1 to the scValue because the bnet is indexed from 1
    posteriorProbS = GetPosteriorProbabilityForSFCategory(scValue+1, info.stage, bnetS);
    
    [kcValue kcHighCard] = cardtype([info.hole_card info.board_card]);
    %adding 1 to the scValue because the bnet is indexed from 1
    posteriorProbK = GetPosteriorProbabilityForNofKindCategory(kcValue+1, info.stage, bnetK);
    
    distribution = [posteriorProbS posteriorProbK];

    %% Fill the opponents expected hand distribution
    oppo_dis = predictholecards(info, bnetS, bnetK);
    
    N = size(info.active, 2);
    for i = 1: N
		if i ~= info.cur_pos && info.active(i) == 1
			distribution = [distribution; oppo_dis(i,:)];
		end
    end
    
    %% ----- FILL IN THE MISSING CODE ----- %%
    win_prob = PredictWin(distribution);
    %% ----- FILL IN THE MISSING CODE ----- %%
    
	%% Calculate the pot odds for raise, call
	%% raise amount depends on the current stage of the game: flop(SBU)/turn(2*SBU)/river(2*SBU)
    raiseamount = SBU;
    if info.stage > 1
        raiseamount = 2*SBU;
    end
    
    T = 0;
    positionRV = GetPosition(info.cur_pos, info.first_pos, sum(info.active));
    if positionRV == 1
        %% case of early position: loose play
        T = 0.15;
    elseif positionRV == 2
        %% case of later position: tight play
        T = -0.15;
    end
    
    pot_odds_raise = (info.cur_pot + raiseamount)/(info.cur_pot + raiseamount + info.pot + raiseamount * N) - T;
    pot_odds_call = info.cur_pot /(info.cur_pot + info.pot) - T;
	
    if win_prob > pot_odds_raise
        decision = 2;
    elseif win_prob > pot_odds_call
        decision = 1;
    else
        decision = 3;
    end
	
    if decision ~= 2
        N = size(info.active, 2);
        oppo_model = cell2mat(info.oppo);
    
        stats = GetStatisticsForCurrentStage(info.cur_pos, info.first_pos, N, oppo_model, info.paid, info.stage);
        decision = MakeDecisionHandStrengthStage(info.stage, stats, info.hole_card, info.board_card);
 
    end
    %% The following is just a sample of randomly generating different
    %% decisions. Please comment them after you finish your part.
    %%num = floor(rand(1)*100);
    %%if (num <= 60)
    %%    decision = 1;
    %%elseif (num <= 90)
    %%    decision = 2;
    %%else
    %%   decision = 3;
    %%end  
end

function OppoHandStrengthStageMat = GetOppoHandStrengthStageMatrix()
    %OPPOCALL = 1; OPPORAISE = 2; OPPORERAISE = 3;
    %CATLESSTHAN3 = 1; CATLESSTHAN4 = 2; CATEQUALTO4 = 3; NP1ROUND = 4; NP2ROUND = 5; JUNK = 6;
    
    %NumStages * NumHandStrengthRows * NumOppoActions Matrix
    OppoHandStrengthStageMat = zeros(3, 6, 3);
    
    %Flop
    OppoHandStrengthStageMat(1, :, :) = [2 2 2; 2 2 2; 2 2 1; 2 1 3; 1 1 3; 3 3 3];
    
    %Turn
    OppoHandStrengthStageMat(2, :, :) = [2 2 2; 2 2 1; 2 1 1; 2 1 1; 3 3 3; 3 3 3];
    
    %Rivers
    OppoHandStrengthStageMat(3, :, :) = [2 2 2; 2 2 1; 1 1 3;1 3 3; 3 3 3; 3 3 3];
end

function decision = MakeDecisionHandStrengthStage(stage, stats, hole_card, board_card)
    %numTightsWhoHaveCalled = stats(1); numTightsWhoHaveRaised = stats(2);
    %numTightsWhoHaveCheckRaised = stats(3); numTightsWhoHaveReRaised = stats(4);
    
    OPPOCALL = 1; OPPORAISE = 2; OPPORERAISE = 3;
    CATLESSTHAN3 = 1; CATLESSTHAN4 = 2; CATEQUALTO4 = 3; NP1ROUND = 4; NP2ROUND = 5; JUNK = 6;
    oppoAction = OPPOCALL;
    if stats(3) >= 0.5 || stats(4) >= 0.5
        oppoAction = OPPORERAISE;
    elseif stats(2) >= 1
        oppoAction = OPPORAISE;
    end
    
    handStrength = JUNK;
    KCategory = cardtype([hole_card board_card]);
    SFCategory = sftype([hole_card board_card]);
    
    NP1RoundVector = [2 4 6 9 11 12 13 14 15 16 18 19 20];
    NP2RoundVector = [3 7 10 17];
    
    if KCategory == 5 || SFCategory == 1 || KCategory == 4  || SFCategory == 5 || SFCategory == 8
        handStrength = CATLESSTHAN3;
    elseif KCategory == 3 || KCategory == 2
        handStrength = CATLESSTHAN4;
    elseif KCategory == 1
        handStrength = CATEQUALTO4;
    elseif any(NP1RoundVector == SFCategory)
        handStrength = NP1ROUND;
    elseif any(NP2RoundVector == SFCategory)
        handStrength = NP2ROUND;
    end
    
    OppoHandStrengthStageMat = GetOppoHandStrengthStageMatrix();
    decision = OppoHandStrengthStageMat(stage, handStrength, oppoAction);
    
end

%% posteriorProbS will contain prob for [SF F S]
function probVector = GetPosteriorProbabilityForSFCategory(scValue, sgValue, bnet)
    probVector = [];
    for sfValue = 2:4 %%we skip the junk stage here
        prob = GetBayesNetProbabilityForSFCategory(sfValue, scValue, sgValue, bnet);
        probVector = [probVector prob];
    end
end

function prob = GetBayesNetProbabilityForSFCategory(sfValue, scValue, sgValue, bnet)
    N=3; 
    SC = 1; SG = 2; SF = 3;    
    
    engine = jtree_inf_engine(bnet);
    evidence = cell(1,N);
    evidence{SC} = scValue;
    evidence{SG} = sgValue;
    [engine, loglik] = enter_evidence(engine, evidence);
    m = marginal_nodes(engine, [SF], 1);
    prob = m.T(sfValue);
end

%% posteriorProbK will contain prob for [K4 K3K2 K3 K2K2 K2]
function probVector = GetPosteriorProbabilityForNofKindCategory(kcValue, sgValue, bnet)
    probVector = [];
    for kfValue = 6:-1:2 %% we skip the case of no pair here
        prob = GetBayesNetProbabilityForNofKindCategory(kfValue, kcValue, sgValue, bnet);
        probVector = [probVector prob];
    end
end

function prob = GetBayesNetProbabilityForNofKindCategory(kfValue, kcValue, sgValue, bnet)
    N=3; 
    KC = 1; SG = 2; KF = 3;
    
    engine = jtree_inf_engine(bnet);
    evidence = cell(1,N);
    evidence{KC} = kcValue;
    evidence{SG} = sgValue;
    [engine, loglik] = enter_evidence(engine, evidence);
    m = marginal_nodes(engine, [KF], 1);
    prob = m.T(kfValue);
end


function win_prob = PredictWin(distribution)
    %% The following is just a sample of randomly generating different
    %% distribution is of form [[Saf Kaf][So1f Ko1f][So2f Ko2f]...]
    win_prob = 1;
    distsize = size(distribution);
    for i = 2:distsize(1)
        win_prob = win_prob * PredictWin2Players([distribution(1,:); distribution(i,:)]);
    end
    %% ONLY for testing, do not forget to comment the following line
    %% win_prob = 1;
end

function win_prob_2player = PredictWin2Players(distribution)
    %% distribution is of form [[Saf Kaf][Sof Kof]]
    sizeSK = size(distribution);
    numWins = 0;
    totalNum = sizeSK(2) * sizeSK(2);

    for i = 1:sizeSK(2)%%numColumns of Sa AND Ka
        for j = 1:sizeSK(2)%%numColumns of So AND Ko
            if distribution(1, i) > distribution(1, j)
                numWins = numWins + 1;
            end
        end
    end
    
    win_prob_2player = numWins / totalNum;
end


function [bnetS, bnetK] = create_bayesnet()
    % create 2 Bayes graph structures corresponding to S and K categories
    N=3;
    dagS=zeros(N,N);dagK = zeros(N,N);
    SC = 1; KC = 1; SG = 2; SF = 3; KF = 3;
    node_names_S={'SC', 'SG', 'SF'};
    node_names_K={'KC', 'SG', 'KF'};
    dagS(SG, SF)=1; dagS(SC, SF) = 1;
    dagK(SG, KF)=1; dagK(KC, KF)=1;
    
    % create structure of each node
    discrete_nodes = 1:N;
    node_sizes_S = [21 3 4];
    node_sizes_K = [6 3 6];
    bnetS = mk_bnet(dagS, node_sizes_S, 'discrete', discrete_nodes, 'names', node_names_S);
    bnetK = mk_bnet(dagK, node_sizes_K, 'discrete', discrete_nodes, 'names', node_names_K);
    
    % List the vector for SF when SF = Junk, StraightFlush, Flush, Straight for stages Flop and Turn
    % I added the Junk vector so as to have entries in each row sum to 1
    SF_Flop_Junk = [1 0 0.396 0.9167 0.518 0 0.6503 0.9584 0 0.6855 0.9556 0.8353 0.6087 0.8223 0.6799 0.7937 0.5254 0.9168 0.6253 0.6828 0.4089];
    SF_Flop_SF = [0 1 0.0842 0.0028 0.0426 0 0 0 0 0 0 0 0.0028 0.0028 0.0028 0 0 0 0 0 0];
    SF_Flop_F = [0 0 0.2784 0.0389 0.3145 1 0.3497 0.0416 0 0 0 0 0.3469 0.0389 0.0389 0.0416 0.3497 0.0416 0.3497 0.0416 0.3497];
    SF_Flop_S = [0 0 0.2414 0.0416 0.1249 0 0 0 1 0.3145 0.0444 0.1647 0.0416 0.1360 0.2784 0.1647 0.1249 0.0416 0.0250 0.2756 0.2414];
      
    % I added the Junk vector so as to have entries in each row sum to 1
    SF_Turn_Junk = [1 0 0.6304 1 0.7174 0 0.8043 1 0 0.8261 1 0.913 1 1 1 1 1 1 1 1 1];
    SF_Turn_SF = [0 1 0.0435 0 0.0217 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    SF_Turn_F = [0 0 0.1522 0 0.1739 1 0.1957 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    SF_Turn_S = [0 0 0.1739 0 0.0870 0 0 0 1 0.1739 0 0.0870 0 0 0 0 0 0 0 0 0];
    
    % These probs are either 0/1 because at the end of the river stage, we know the final hand accurately
    SF_River_Junk = [1 0 1 1 1 0 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1];
    SF_River_SF = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    SF_River_F = [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    SF_River_S = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0];
    
    SF_Junk = [SF_Flop_Junk SF_Turn_Junk SF_River_Junk];
    SF_SF = [SF_Flop_SF SF_Turn_SF SF_River_SF];
    SF_F = [SF_Flop_F SF_Turn_F SF_River_F];
    SF_S = [SF_Flop_S SF_Turn_S SF_River_S];
    
    SFVector = [SF_Junk SF_SF SF_F SF_S];
    
    % List the vector for KF when KF = Junk, K2, K2K2, K3, K3K2, K4
    % Somehow, my comment parser produces this distribution in the wrong
    % order. Check that code again
    KF_Flop_Junk = [0.4589 0 0 0 0 0];
    KF_Flop_K2 = [0.4440 0.6075 0 0 0 0];
    KF_Flop_K2K2 = [0.0832 0.3000 0.8362 0 0 0];
    KF_Flop_K3 = [0.0139 0.0666 0.0000 0.8325 0 0];
    KF_Flop_K3K2 = [0.0000 0.0250 0.1619 0.1249 0.9565 0];
    KF_Flop_K4 = [0.0000 0.0009 0.0019 0.0426 0.0435 1];
    
    KF_Turn_Junk = [0.609 0 0 0 0 0];
    KF_Turn_K2 = [0.3910 0.6956 0 0 0 0];
    KF_Turn_K2K2 = [0 0.2609 0.913 0 0 0];
    KF_Turn_K3 = [0 0.0435 0 0.7823 0 0];
    KF_Turn_K3K2 = [0 0 0.0870 0.1960 0.9783 0];
    KF_Turn_K4 = [0.0000 0.0000 0.0000 0.0217 0.0217 1];
    
    % These probs are either 0/1 because at the end of the river stage, we know the final hand accurately
    KF_River_Junk = [1 0 0 0 0 0];
    KF_River_K2 = [0 1 0 0 0 0];
    KF_River_K2K2 = [0 0 1 0 0 0];
    KF_River_K3 = [0 0 0 1 0 0];
    KF_River_K3K2 = [0 0 0 0 1 0];
    KF_River_K4 = [0 0 0 0 0 1];
    
    KF_Junk = [KF_Flop_Junk KF_Turn_Junk KF_River_Junk];
    KF_K2 = [KF_Flop_K2 KF_Turn_K2 KF_River_K2];
    KF_K2K2 = [KF_Flop_K2K2 KF_Turn_K2K2 KF_River_K2K2];
    KF_K3 = [KF_Flop_K3 KF_Turn_K3 KF_River_K3];
    KF_K3K2 = [KF_Flop_K3K2 KF_Turn_K3K2 KF_River_K3K2];
    KF_K4 = [KF_Flop_K4 KF_Turn_K4 KF_River_K4];
    
    KFVector = [KF_Junk KF_K2 KF_K2K2 KF_K3 KF_K3K2 KF_K4];
    
    % define the CPT/parameters
    bnetS.CPD{SF} = tabular_CPD(bnetS, SF, SFVector);
    bnetK.CPD{KF} = tabular_CPD(bnetK, KF, KFVector);
    
    %% added these dummy CPTs because bnt toolkit throws up an error
    bnetS.CPD{SC} = tabular_CPD(bnetS, SC, ones(1, node_sizes_S(SC))/node_sizes_S(SC));
    bnetS.CPD{SG} = tabular_CPD(bnetS, SG, ones(1, node_sizes_S(SG))/node_sizes_S(SG));
    
    bnetK.CPD{KC} = tabular_CPD(bnetK, KC, ones(1, node_sizes_K(KC))/node_sizes_K(KC));
    bnetK.CPD{SG} = tabular_CPD(bnetK, SG, ones(1, node_sizes_K(SG))/node_sizes_K(SG));
    
    % draw graph
    % draw_graph(bnetS.dag);
    % draw_graph(bnetK.dag);
end
