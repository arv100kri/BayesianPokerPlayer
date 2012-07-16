%% Stage Updater
%%
%% INPUT: a structure "info" containing the following field
%%        stage, pot, cur_pos, cur_pot, first_pos, board card,
%%        hole_card, active, paid, history, su_info, oppo_model, historyA
%% OUTPUT : a matrix su_info recording the info you want to save,
%%          this matrix will be included in the "info" in the 
%%          MakeDecision function

function su_info = StageUpdater(info)
    %NOTE: I think it is simpler to update all stages rather than updating only the last two stages.
    %This is because of the constraints imposed by info.history.bet and info.paid.
    %history.bet can be used only after the current game is finished
    %info.paid has to be used for making decisions in the current stage of the game
    
    %It is better to start off with a clean slate rather than make incremental updates to su_info
    su_info = [];
    N = size(info.active, 2);
    SBU = 10;
    BettingAmount = SBU;
    
    if info.stage >= 3
        BettingAmount = 2*SBU;
    end
  
    %compute the feature values representing the betting behaviour for this game for a particular player
    NUMFEATURES = 8;
    %features per player are:
    NUMCALLSINPREFLOP = 1;
    NUMRAISESINPREFLOP = 2;
    NUMCHECKRAISESINPREFLOP = 3;
    NUMRERAISESINPREFLOP = 4;
    NUMCALLSTOTAL = 5;
    NUMRAISESTOTAL = 6;
    NUMCHECKRAISESTOTAL = 7;
    NUMRERAISESTOTAL = 8;
    
    CALL = 1; RAISE = 2;

    if size(info.su_info,2) == 0
        su_info = zeros(N, NUMFEATURES);
    end
    
    for player = 1:N
        featureVector = zeros(1, NUMFEATURES);
        if player ~= info.cur_pos % info.cur_pos is just the agent when the call comes to this function
          for stage = 0:info.stage-1
            %ARVIND: Replacing history with redundant historyA variable
            %there will be atleast one occurence of historyA.bet for stages < info.stage
            startRound = info.historyA.stage_starts(stage+1);
            endRound = size(info.historyA.bet, 1);
            if stage ~= info.stage - 1
              endRound = info.historyA.stage_starts(stage+2)-1;
            end
            
            for round = startRound:endRound
            
              if info.historyA.bet(round, player) == CALL
                featureVector(NUMCALLSTOTAL) = featureVector(NUMCALLSTOTAL) + 1;
              elseif info.historyA.bet(round, player) == RAISE
                featureVector(NUMRAISESTOTAL) = featureVector(NUMRAISESTOTAL) + 1;
              end
              
              if round > startRound && info.historyA.bet(round, player) == RAISE && info.historyA.bet(round -1, player) == CALL
                featureVector(NUMCHECKRAISESTOTAL) = featureVector(NUMCHECKRAISESTOTAL) + 1;
              elseif round > startRound && info.historyA.bet(round, player) == RAISE && info.historyA.bet(round -1, player) == RAISE
                featureVector(NUMRERAISESTOTAL) = featureVector(NUMRERAISESTOTAL) + 1;
              end
              
            end
            
            if stage == 0
              %compute the features for preflop stage
              featureVector(NUMCALLSINPREFLOP) = featureVector(NUMCALLSTOTAL);
              featureVector(NUMRAISESINPREFLOP) = featureVector(NUMRAISESTOTAL);
              featureVector(NUMCHECKRAISESINPREFLOP) = featureVector(NUMCHECKRAISESTOTAL);
              featureVector(NUMRERAISESINPREFLOP) = featureVector(NUMRERAISESTOTAL);
            end
          end
          

          % we again have only the paid variable for the current stage
          % info.historyA.bet is updated for all the previous stages.
          % hence this will be an approximation
          if info.paid(player) >= BettingAmount
            featureVector(NUMCALLSTOTAL) = featureVector(NUMCALLSTOTAL) + 1;
          end

          if info.paid(player) > BettingAmount
            featureVector(NUMRAISESTOTAL) = featureVector(NUMRAISESTOTAL) + (info.paid(player) - BettingAmount)/BettingAmount;
          end
          
          if info.paid(player) >= 2*BettingAmount %one call followed by one raise
            featureVector(NUMCHECKRAISESTOTAL) = featureVector(NUMCHECKRAISESTOTAL) + 1;
          end
          
          if info.paid(player) > 2*BettingAmount %N raises followed by another raise
            featureVector(NUMRERAISESTOTAL) = featureVector(NUMRERAISESTOTAL) + (info.paid(player) - 2*BettingAmount)/BettingAmount;;
          end
          
          if info.stage == 0
              %compute the features for preflop stage
              featureVector(NUMCALLSINPREFLOP) = featureVector(NUMCALLSTOTAL);
              featureVector(NUMRAISESINPREFLOP) = featureVector(NUMRAISESTOTAL);
              featureVector(NUMCHECKRAISESINPREFLOP) = featureVector(NUMCHECKRAISESTOTAL);
              featureVector(NUMRERAISESINPREFLOP) = featureVector(NUMRERAISESTOTAL);
          end
        end
        
        su_info = [su_info;featureVector];
    end
  	
  %% MOVED THE PORTION BELOW TO MAKEDECISION
  %% ----- FILL IN THE MISSING CODE ----- %%
  
  %%oppo_dis = PredictHoleCards(info);
  
  %% ----- FILL IN THE MISSING CODE ----- %%
end

%% MOVED THIS FUNCTION TO MAKEDECISION
%%function oppo_dis = PredictHoleCards(info)
%%    oppo_dis = [];
%%    %% ----- FILL IN THE MISSING CODE ----- %%
%%end