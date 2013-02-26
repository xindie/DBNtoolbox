classdef Kmeans < handle & Learner    
    %           kihyuk's library has a pretty nice function
	% implement kmeans++ initialization? http://en.wikipedia.org/wiki/K-means%2B%2B
    properties                
        weights;       %feadim*numunits                
        feadim;
        numunits;        
        
        type; %activation type                
        threshold = 0.1; %for type 'soft' (Adam Coaste used 0.1, 0.25, 0.5, 1.0)                
        
        %temporary variable
        numassigned; 
        prev_numassigned;
    end
    
    methods
        function self = Kmeans(N, type)            
            self.numunits = N;
            self.type = type;                     
        end

        function train(self, X)               
            %deal with empty center better            
            
            %re-implement this later    
            % if ~isempty(savedir_s)
                % savedir = sprintf('/mnt/neocortex/scratch/suii/basis/%s',savedir_s);
                % if exist(savedir,'dir')
                    % disp('warning : directory already exist');
                % else
                    % mkdir(savedir);
                % end
            % end
            self.feadim = size(X,1);                        
            [~, theta] = Kmeans.kmeanslite(X,self.numunits, self.max_iter);
            self.weights = theta;
                
            % if ~isempty(savedir_s)
                % learner_id = sprintf('Kmeans_%s_N%g',self.type,self.numunits);
                % fname_save = sprintf('%s/%s', savedir , learner_id);            
                % fname_mat = sprintf('%s.mat', fname_save);
                % fname_png_1 = sprintf('%s_1.png', fname_save);                        

                % self.savepath = [savedir_s , '_' , learner_id];

                % DeepBeliefNetwork.save_progress(self, fname_mat, fname_png_1);
            % end
        end        
        
        %for batch update-----------------------------
        %TODO: init (init label first), checkend        
        
        function [] = initialization(self, X)
            if isempty(self.weights)
                self.feadim = size(X,1); 
                n  = size(X,2);
                label = ceil(self.numunits*rand(n,1));
                E = sparse(1:n,label,1,n,self.numunits,n);  % transform label into indicator matrix
                self.weights = X*(E*spdiags(1./sum(E,1)',0,self.numunits,self.numunits));    % compute center of each cluster
            end
        end
        
        function [] = initIter(self,t)
            if t > 1
                self.prev_numassigned = self.numassigned;
            end
            self.numassigned = zeros(self.numunits,1);            
        end
        
        function [] = update(self, X)                        
            %update function for sequential Kmeans                        
            [val,label] = max(bsxfun(@minus,self.weights'*X,0.5*sum(self.weights.^2,1)')); % assign samples to the nearest centers                                    
            binlabel = Utils.num2bin(label,self.numunits); %numunits *numdata
            new_assign = sum(binlabel,2);
            self.numassigned = self.numassigned + new_assign;            
            isupdate = new_assign ~= 0;
            
            delta = X*binlabel';
            self.weights(:,isupdate) = self.weights(:,isupdate) + bsxfun(@rdivide,(delta(:,isupdate) - bsxfun(@times,self.weights(:,isupdate),new_assign(isupdate)')) , self.numassigned(isupdate)');
        end
        
        function [isstop] = checkStop(self)
            isstop = false;
            if ~isempty(self.prev_numassigned) && nnz(self.numassigned ~= self.prev_numassigned) == 0
                isstop = true;
            end
        end
        %--------------------------------------------------
        
        % function train_old(self, savedir_s, Data, debug)               
            % X = Data.Xtrain;
            % self.numchannels = Data.numchannels;
            % self.prev_learner = Data.learner; 
            % clear Data;
                            
            
            % savedir = sprintf('/mnt/neocortex/scratch/suii/basis/%s',savedir_s);
            % if exist(savedir,'dir')
                % disp('warning : directory already exist');
            % else
                % mkdir(savedir);
            % end
            % X = X';
            % k = self.numunits;
            
            % x2 = sum(X.^2,2);
            % centroids = randn(k,size(X,2))*0.1; %X(randsample(size(X,1), k), :);
            % BATCH_SIZE=1000;
            % iterations = 50;
            % loss_history = zeros(iterations,1);
            
            % if exist('debug','var') && ~isempty(debug) && debug 
                % iterations = 1;
            % end
              % for itr = 1:iterations
                % fprintf('K-means iteration %d / %d\n', itr, iterations);

                % c2 = 0.5*sum(centroids.^2,2);

                % summation = zeros(k, size(X,2));
                % counts = zeros(k, 1);

                % loss =0;

                % for i=1:BATCH_SIZE:size(X,1)
                  % lastIndex=min(i+BATCH_SIZE-1, size(X,1));
                  % m = lastIndex - i + 1;

                  % [val,labels] = max(bsxfun(@minus,centroids*X(i:lastIndex,:)',c2));
                  % loss = loss + sum(0.5*x2(i:lastIndex) - val');

                  % S = sparse(1:m,labels,1,m,k,m); % labels as indicator matrix
                  % summation = summation + S'*X(i:lastIndex,:);
                  % counts = counts + sum(S,1)';
                % end
                
                % loss_history(itr) = loss;
                % centroids = bsxfun(@rdivide, summation, counts);

                % just zap empty centroids so they don't introduce NaNs everywhere.
                % badIndex = find(counts == 0);
                % centroids(badIndex, :) = 0;
              % end            
            
               % self.weights = centroids';
               
            % learner_id = sprintf('Kmeans_%s_N%g',self.type,self.numunits);
            % fname_save = sprintf('%s/%s', savedir , learner_id);            
            % fname_mat = sprintf('%s.mat', fname_save);
            % fname_png_1 = sprintf('%s_1.png', fname_save);                        
            % fname_png_2 = sprintf('%s_2.png', fname_save); 
            
            % self.savepath = [savedir_s , '_' , learner_id];
            
            % DeepBeliefNetwork.save_progress(self, fname_mat, fname_png_1,fname_png_2, {loss_history}, {'loss_history'});
        % end
               
        
        function [acti] = fprop(self, patches)
                patches = fprop@Learner(self,patches);
            
                numsamples = size(patches,2);
                patches = patches';
                centroids = self.weights';
                xx = sum(patches.^2, 2);
                cc = sum(centroids.^2, 2)';
                xc = patches * centroids';   %numsamples * numunits

                z = real(sqrt( bsxfun(@plus, cc, bsxfun(@minus, xx, 2*xc)) )); % distances, real for numerical error
            switch self.type
                case 'tri'
                    mu = mean(z, 2); % average distance to centroids for each patch
%                    mu = mean(z, 1); % mean of each centroids
                    acti = max(bsxfun(@minus, mu, z), 0)';
                case 'soft'
                    acti = max(0,xc-self.threshold)';                    
                case 'hard'
                    [v, inds] = min(z,[],2);
					acti = zeros(self.numunits, numsamples);
                    idx = full(sparse([1:numsamples]', inds, ones(numsamples,1 ) ))';
					acti(1:size(idx,1),:) = idx;
            end
        end
        
        
		function [weights] = show_basis(self,dum)
			weights = self.weights;
		end
        
    end
    
    methods(Static)
        function [label,center] = kmeanslite(X, k, MAX_ITERS)

            if ~exist('opt_verbose', 'var')
                opt_verbose = true;
            end
    
            if ~exist('MAX_ITERS', 'var')
                MAX_ITERS = 50;
            end
    
            n = size(X,2);
            last = 0;
            label = ceil(k*rand(1,n));  % random initialization
            itr=0;
            % MAX_ITERS=50;
            while any(label ~= last)
                itr = itr+1;
                if opt_verbose
                    fprintf( '%d(%d)..', itr, sum(label ~= last));
                end
    
                E = sparse(1:n,label,1,n,k,n);  % transform label into indicator matrix
                center = X*(E*spdiags(1./sum(E,1)',0,k,k));    % compute center of each cluster
                last = label;
                [val,label] = max(bsxfun(@minus,center'*X,0.5*sum(center.^2,1)')); % assign samples to the nearest centers
                if (itr >= MAX_ITERS) break; end;
            end
            % center=center';
    
            if opt_verbose
                fprintf('\n');
            end       
        end
  end
end