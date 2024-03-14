%This script is half automatic, this part of the script creates the PDU subsystem and save the PDU names which will be later used. Load this first before the second part.

%Parameters, path configuration
model='<<model-name>>'; %Simulink model name

%create a subsystem and a bus creator in it and connec to the model
systemPath='<<path-to-subsystem>>'; %change this
sysBCPath=[systemPath '/Bus Creator1'];
databaseName = "<<database-name>>"; %change this
node='<<node-name>>'; %change this

subsystemNames= [];

%create subsystem block in system path
inputPDU = get_param(sysBCPath,'InputSignalNames');
inputPDUlist= [];

    for z=1:length(inputPDU)
        if z == length(inputPDU)
            inputPDUlist=[inputPDUlist,[inputPDU{z}]];
        else
            inputPDUlist=[inputPDUlist,[inputPDU{z} ',']];
        end
    end  
unassignedPDU=length(inputPDU);

%delete lines to prevent errors
systemHandle=getSimulinkBlockHandle(systemPath,true);
PDULineHandles=find_system(systemHandle,'FindAll', 'on', 'Type', 'Line');  
delete_line(PDULineHandles)
for j=1:unassignedPDU
   %create subsystem block
   subsystemName=[systemPath '/Subsystem_'  inputPDU{j}];
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
   sysBCPosition = get_param(sysBCPath, 'Position'); 
   subsystemPostion = [sysBCPosition(1)-300, sysBCPosition(2)+85*(j-1),...
   sysBCPosition(1)-200, sysBCPosition(2)+85*j-30];
   set_param(subsystemName,'Position', subsystemPostion);
   
end