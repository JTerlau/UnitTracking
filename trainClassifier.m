
% train classifier using labeled waveform features

function [mdl, normTrain, CV] = trainClassifier(sessionSplits)


Xw = getSimFeatures(sessionSplits,'within');
Xa = getSimFeatures(sessionSplits,'across');


%% min max normalization
normTrain.min = min([Xw;Xa]);
normTrain.max = max([Xw;Xa]);

Xw_norm = (Xw-normTrain.min) ./ (normTrain.max-normTrain.min);
Xa_norm = (Xa-normTrain.min) ./ (normTrain.max-normTrain.min);

X = [Xw_norm;Xa_norm];

Y = categorical([ones(size(Xw,1),1);2*ones(size(Xa,1),1)]);

% 1. Cross-validation (optional)
if nargout > 2

    k = 10;
    cv = cvpartition(Y,'KFold',k);

    CV.true  = double(Y);
    CV.pred  = zeros(size(Y));
    CV.prob  = zeros(size(Y));

    for iFold = 1:k
        trainIdx = training(cv,iFold);
        testIdx  = test(cv,iFold);

        % Train SVM
        mdlOrig = fitcsvm(X(trainIdx,:), Y(trainIdx), ...
            'Standardize',true);

        % training
        mdlOrig = fitPosterior(mdlOrig, X(trainIdx,:), Y(trainIdx));

        % testing
        [lbl, p] = predict(mdlOrig, X(testIdx,:));

        CV.pred(testIdx) = lbl;
        CV.prob(testIdx) = p(:,1); % P(Match)
    end

    CV.acc = mean(CV.pred == CV.true);
    
end

% 2. Final model
mdlOrig = fitcsvm(X,Y);
mdl = fitPosterior(mdlOrig, X,Y);



