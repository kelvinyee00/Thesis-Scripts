%After copy and paste the bus creator with their signal names on the lines together into each of the PDU Subsystems.

%for each subsystems
for i = 1:unassignedPDU
    subsystemName=[systemPath '/Subsystem_'  inputPDU{i}];
    BCInportHandle=get_param(sysBCPath, 'PortHandles');
    subsystemOutportHandle=get_param(subsystemName, 'PortHandles');
    
    PDULineHandle=add_line(systemPath,subsystemOutportHandle.Outport(1),BCInportHandle.Inport(i));
    %rename the pdu lines here
    set_param(PDULineHandle, 'Name' , inputPDU{i});
    %subsystem Handles
    blockPath = [subsystemName '/Bus Creator'];
    inputSignalList = get_param(blockPath, 'InputSignalNames');
    
    %subsystem handle
    subsystemHandle=getSimulinkBlockHandle(subsystemName,true);
    unwantedLineHandle=find_system(subsystemHandle,'FindAll', 'on', 'Type', 'Line');  
    delete_line(unwantedLineHandle);
    
    unassignedSignals = length(inputSignalList);
    for k = 1 : unassignedSignals
        %set block config
       vectorBlockName = [subsystemName '/Inport_' inputSignalList{k}];
       add_block("canoelib/CANoe I//O/Signal Input",vectorBlockName,'MakeNameUnique', 'on');
       PDU= string(inputPDU{i});
       signal= string(inputSignalList(k));
       set_param(vectorBlockName,'dbName', databaseName, 'nodeName', node, 'msgName',PDU,'sigName',signal);
       
       %vector block positions
       subSysBCPosition = get_param(blockPath, 'Position'); %ref position of BC
       startCoord = subSysBCPosition(2) + (subSysBCPosition(4) - subSysBCPosition(2))/unassignedSignals*(k-1);
       offset = ((subSysBCPosition(4) - subSysBCPosition(2))/unassignedSignals - 40)/2;
       vectorBlockPosition = [subSysBCPosition(1)-280, startCoord+offset,...
       subSysBCPosition(1)-200, startCoord+offset+40];
       set_param(vectorBlockName, 'Position', vectorBlockPosition); 
       
       %delete existing lines and then reconnect and rename
       blockPathHandle= get_param(blockPath,'PortHandles');
       vectorBlockHandle = get_param(vectorBlockName, 'PortHandles');
       signalLineHandle=add_line(subsystemName,vectorBlockHandle.Outport(1), blockPathHandle.Inport(k), 'autorouting', 'on');
       set_param(signalLineHandle, 'Name' , inputSignalList{k});
    end
    outputHandle=get_param([subsystemName '/Out1'] ,'PortHandles');
    add_line(subsystemName, blockPathHandle.Outport(1), outputHandle.Inport(1));
end    