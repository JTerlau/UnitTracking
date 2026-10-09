
% train classifier using labeled waveform features

function [mdl, normTrain, CV] = trainClassifier(sessionSplits)


Xs = getSimFeatures(sessionSplits,'same');
Xd = getSimFeatures(sessionSplits,'different');


%% min max normalization
normTrain.min = min([Xd;Xs]);
normTrain.max = max([Xd;Xs]);

Xs_norm = (Xs-normTrain.min) ./ (normTrain.max-normTrain.min);
Xd_norm = (Xd-normTrain.min) ./ (normTrain.max-normTrain.min);

X = [Xs_norm;Xd_norm];

Y = categorical([ones(size(Xd,1),1);2*ones(size(Xs,1),1)]);

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

        CV.pred(testIdx) = double(lbl);
        CV.prob(testIdx) = p(:,1); % P(Match)
    end

    CV.acc = mean(CV.pred == CV.true);
    
end

% 2. Final model
mdlOrig = fitcsvm(X,Y);
mdl = fitPosterior(mdlOrig, X,Y);




