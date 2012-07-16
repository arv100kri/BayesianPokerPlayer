%% Update Opponent Model
%%
%% INPUT: a matrix recording K round history info containing
%%        the following field
%%        showdown: K by 1 binary vector, recording if a game finally went
%%                  to a showdown stage.
%%        board:    k by 5 matrix, recording all the board cards
%%        hole:     k by N*2 matrix, recording hole cards for all players.
%%                  If a player folds, his cards are hidden (-1)
%%        bet:      k*4 by N, betting history of each player in four
%%                  rounds.
%%
%% OUTPUT: a matrix recording opponent model parameters


% i assume that this function updates the history for the ith player
% i have only represented the position based style of the ith player
% Assume oppo_model is of the form [8 column vector for player1; 8 column vector for player2; and so on...
% The first 8 columns represent combination of the form LAE(Loose Aggr Early), TAE, LPE, TPE, LAL, TAL, LPL, TPL
% These 8 columns represent the probability that a particular opponent is in this combination of (Loose/Tight) + (Passive/Aggr) + (Early/Late)
% TODO: Add additional columns for the bluffs once i compute them
function oppo = UpdateOpponent(history,i)
    oppo = [];
    
    %% ----- FILL IN THE MISSING CODE ----- %%
    %LAE = 1; TAE = 2; LPE = 3; TPE = 4;
    %LAL = 5; TAL = 6; LPL = 7; TPL = 8;
    
    % compute this for both early and late games
    % for non-early or non-late games, compute the prob and add half of it to both
    
    % probLoose = numGames Participated Beyond flop stage / numGames that went beyond flop stage
    % probTight = 1 - probLoose
    
    % probAggressive = numGames CheckRaised/Reraised / numGames
    % probPassive = 1 - probAggressive
    
    NUM_OPPOMODEL_FEATURES = 8;
    numGames = size(history.board, 1);
    N = size(history.bet, 2);
    CALL = 1; RAISE = 2; %FOLD = 3;
    
    for player = 1:N
        
        oppo_player = 2*ones(1,NUM_OPPOMODEL_FEATURES)/NUM_OPPOMODEL_FEATURES;
        featureVector = zeros(1, NUM_OPPOMODEL_FEATURES);
        pos = 0;
        for game = 1:numGames
            pos = mod(pos+1,N);
            first_pos = pos + 1;

            didGameGoBeyondFlopStage = false;
            if sum(history.bet(history.start(game, 3),:)) > 0
                didGameGoBeyondFlopStage = true;
            end

            participatedBeyondFlopStage = false;
            if history.bet(history.start(game, 3), player) > 0
                participatedBeyondFlopStage = true;
            end

            checkRaised = false;
            reRaised = false;

            for stage = 1:4
                startRound = history.start(game, stage);
                endRound = size(history.bet, 1);
                if stage == 4 && game ~= numGames
                    endRound = history.start(game+1, 1)-1;
                elseif stage ~=4
                    endRound = history.start(game, stage + 1)-1;
                end
                
                for round = startRound+1:endRound
                    if history.bet(round) == RAISE && history.bet(round - 1) == CALL
                        checkRaised = true;
                    end

                    if history.bet(round) == RAISE && history.bet(round - 1) == RAISE
                        reRaised = true;
                    end
                end
            end

            positionRV = GetPosition(player, first_pos, N);
            if positionRV == 1 || positionRV == 2
                if participatedBeyondFlopStage
                    featureVector((positionRV - 1)*4 + 1) = featureVector((positionRV - 1)*4 + 1) + 1;
                end

                if didGameGoBeyondFlopStage
                    featureVector((positionRV - 1)*4 + 2) = featureVector((positionRV - 1)*4 + 2) + 1;
                end

                if checkRaised || reRaised
                    featureVector((positionRV - 1)*4 + 3) = featureVector((positionRV - 1)*4 + 3) + 1;
                end

                featureVector(4*positionRV) = featureVector(4*positionRV) + 1;
            else
                % add equally to both early and late probabilities
                for positionRVDummy = 1:2
                    if participatedBeyondFlopStage
                        featureVector((positionRVDummy - 1)*4 + 1) = featureVector((positionRVDummy - 1)*4 + 1) + 1;
                    end

                    if didGameGoBeyondFlopStage
                        featureVector((positionRVDummy - 1)*4 + 2) = featureVector((positionRVDummy - 1)*4 + 2) + 1;
                    end

                    if checkRaised || reRaised
                        featureVector((positionRVDummy - 1)*4 + 3) = featureVector((positionRVDummy - 1)*4 + 3) + 1;
                    end

                    featureVector(4*positionRVDummy) = featureVector(4*positionRVDummy) + 1;

                end

            end

        end

        % compute the oppo vector
        for islate=0:1
            if featureVector(4*islate + 2) > 0 && featureVector(4*islate + 4) > 0
                oppo_player(4*islate + 1) = (featureVector(4*islate + 1)/featureVector(4*islate + 2)) * (featureVector(4*islate + 3)/featureVector(4*islate + 4));
                oppo_player(4*islate + 2) = (1- featureVector(4*islate + 1)/featureVector(4*islate + 2)) * (featureVector(4*islate + 3)/featureVector(4*islate + 4));
                oppo_player(4*islate + 3) = (featureVector(4*islate + 1)/featureVector(4*islate + 2)) * (1 - featureVector(4*islate + 3)/featureVector(4*islate + 4));
                oppo_player(4*islate + 4) = (1- featureVector(4*islate + 1)/featureVector(4*islate + 2)) * (1 - featureVector(4*islate + 3)/featureVector(4*islate + 4));
            end
        end


        % normalize the probabilities for early and late separately
        if sum(oppo_player(1:4)) > 0
            oppo_player(1:4) = oppo_player(1:4) / sum(oppo_player(1:4));
        end

        if sum(oppo_player(5:8)) > 0
            oppo_player(5:8) = oppo_player(5:8) / sum(oppo_player(5:8));
        end
        
        
        oppo = [oppo; oppo_player];
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