%Parameters, path configuration
model='<<model-name>>'; %Simulink model name

%create a subsystem and a bus selector in it and connec to the model
systemPath='<<path-to-subsystem>>'; %change this
sysBSPath=[systemPath '/Bus Selector']; 
databaseName = "<<database-name>>"; %change this
node='<<node-name>>'; %change this
PDU_List_Ch_req = ["<<PDU-that-has-ChA/B-in-Database"]; %list all the PDus that required ChA/B
append_Ch_A =1; %set bit when required ChA
append_Ch_B =1;%set bit when required ChB

subsystemNames= [];

%create subsystem block in system path
outputPDU = get_param(sysBSPath,'OutputSignals');
outputPDUList=strsplit(outputPDU, ',');
unassignedPDU=length(outputPDUList);

%configuring in the system Subsystem Block
for j=1:unassignedPDU
   %create subsystem block of the PDUs
   subsystemName=[systemPath '/Subsystem_'  outputPDUList{j}];
   subsystemNames =[subsystemNames,[subsystemName ',']];
   add_block('simulink/Commonly Used Blocks/Subsystem',subsystemName,'MakeNameUnique', 'on');
   %delete content of subsystem
   subsystemHandle=getSimulinkBlockHandle(subsystemName,true);
   
   %unwanted blocks
   unwantedBlockHandles=find_system(subsystemHandle, 'SearchDepth', 1, 'Type', 'Block'); 
   unwantedBlockHandles=unwantedBlockHandles(unwantedBlockHandles ~= subsystemHandle); %exclude subsystem
 
   %unwanted line
   unwantedLineHandle=find_system(subsystemHandle,'FindAll', 'on', 'Type', 'Line');  
   delete_line(unwantedLineHandle)
   delete_block(unwantedBlockHandles);
   
   %reposition subsystem block
   sysBSPosition = get_param(sysBSPath, 'Position'); 
   startCoord = sysBSPosition(2) + (sysBSPosition(4) - sysBSPosition(2))/unassignedPDU*(j-1);
   offset = ((sysBSPosition(4) - sysBSPosition(2))/unassignedPDU - 40)/2;
   
   subsystemPostion = [sysBSPosition(1)+200, startCoord+offset,...
       sysBSPosition(1)+300, startCoord+offset+40];
   set_param(subsystemName,'Position', subsystemPostion);

   %inport in subsystem
   inputName= [subsystemName '/In1'];
   signalBSName = [subsystemName '/Bus Selector'];
   add_block('simulink/Commonly Used Blocks/In1',inputName,'MakeNameUnique', 'on');

   %bs in subsystem
   add_block('simulink/Commonly Used Blocks/Bus Selector',signalBSName,'MakeNameUnique', 'on');
   
   %port handles
   inputHandle = get_param(inputName, 'PortHandles');
   signalBSHandle = get_param(signalBSName, 'PortHandles');
   add_line(subsystemName, inputHandle.Outport(1),signalBSHandle.Inport(1));
   
   
    blockPath = [subsystemName '/Bus Selector'];
    %ports handles
    BSOutportHandle=get_param(sysBSPath, 'PortHandles');
    subsystemInportHandle=get_param(subsystemName, 'PortHandles');
    
    add_line(systemPath,BSOutportHandle.Outport(j),subsystemInportHandle.Inport(1));
    inputcell = get_param(blockPath, 'InputSignals');
    inputlist= [];

    for z=1:length(inputcell)
        if z == length(inputcell)
            inputlist=[inputlist,[inputcell{z}]];
        else
            inputlist=[inputlist,[inputcell{z} ',']];
        end
    end   
    set_param(blockPath,'OutputSignals', inputlist)

    %save names for vector block config ltr
    outputSignals = get_param(blockPath, 'OutputSignals');  
    outputSignalList = strsplit(outputSignals,',');
    unassignedPins = length(outputSignalList);
    lengthBS=100*unassignedPins;
    set_param(inputName, 'position', [0,lengthBS/2-10,40,lengthBS/2+10]);
    set_param(signalBSName, 'position', [60,0,65,lengthBS]);

    %configuring in the msg subsystem block
    for i =1:unassignedPins
        %set block config
       vectorBlockName = [subsystemName '/Outport_' outputSignalList{i}];
       add_block("canoelib/CANoe I//O/Signal Output",vectorBlockName,'MakeNameUnique', 'on')
       for t=1:length(PDU_List_Ch_req)
 
            if string(outputPDUList{j}) == string(PDU_List_Ch_req{t})
            
                if append_Ch_A == 1
                    PDU= [outputPDUList{j} '_Ch_A'];
                    %disp(['success' PDU]);
                    break
                elseif append_Ch_B == 1
                    PDU= [outputPDUList{j} '_Ch_B'];
                    break
                else
                    disp('error');
                end
            end
        
        if t == length(PDU_List_Ch_req)
            PDU= string(outputPDUList{j});
        end
       end
       signal= string(outputSignalList(i));
       set_param(vectorBlockName,'dbName', databaseName, 'nodeName', node, 'msgName',PDU,'sigName',signal);

       %set block position
       busSelectorPosition = get_param(blockPath, 'Position');  
       startCoord = busSelectorPosition(2) + (busSelectorPosition(4) - busSelectorPosition(2))/unassignedPins*(i-1);
       offset = ((busSelectorPosition(4) - busSelectorPosition(2))/unassignedPins - 50)/2;
       vectorBlockPosition = [busSelectorPosition(1)+200, startCoord+offset,...
       busSelectorPosition(1)+280, startCoord+offset+50];
       set_param(vectorBlockName, 'Position', vectorBlockPosition);

        % Find the index of the signal in the Bus Selector's output signals list  
        signalIndex = find(strcmp(outputSignalList, outputSignalList{i})); 
        % Create the input port name using the signal index  
        outportHandle = get_param(blockPath,'PortHandles');
        vectorBlockHandle = get_param(vectorBlockName, 'PortHandles');
        add_line(subsystemName,outportHandle.Outport(signalIndex), vectorBlockHandle.Inport(1), 'autorouting', 'on');
    end    
    

   

end
