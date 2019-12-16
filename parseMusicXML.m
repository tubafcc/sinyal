function mxml = parseMusicXML(filename)

% Test to see if we're in Octave
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

if (isOctave)
    pkg load io
    % make sure Xerces2 jar files are loaded or put them in the folder
    % where the script will run and uncomment below.
    % javaaddpath ("./xercesImpl.jar");
    % javaaddpath ("./xml-apis.jar");
    
    fid = fopen(filename, 'rt');
    content = fread(fid, '*char')';
    fclose(fid);
    newcontent = regexprep(content, '\n\s*?<!DOCTYPE.*?>', '');
    fout = fopen('temp.xml', 'wt');
    fwrite(fout, newcontent);
    fclose(fout);
    
    dom = xmlread('temp.xml');
else
    % Create the DocumentBuilder
    builder = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');

    % Disable validation (because of MATLAB's xmlread bug)
    builder.setFeature('http://apache.org/xml/features/nonvalidating/load-external-dtd', false); 
    
    dom = xmlread(filename, builder);
end
beatCounter = 0;
currBeats = NaN;
currBeatType = NaN;
currKey = 0; % default C maj
%currAccidentals = [0, 0, 0, 0, 0, 0, 0]; % will be initialized below
currTempo = 100; % default tempo 100 bpm
currDyn = 'n'; % no dynamics indication
currWedge = 'n'; % no wedge
currOrnam = 'n'; % no ornamentation
currDynOnset = 0;
slurStarted = 0;
ind = 1; % note array index

% parse first 'part'
part = dom.getElementsByTagName('part').item(0);
measures = part.getElementsByTagName('measure');
mxml(measures.getLength, 19) = NaN; % minimal preallocation
for i = 0:(measures.getLength()-1)

    % parse each measure
    measure = measures.item(i);
    measureNum = javaMethod('parseInt', 'java.lang.Integer', measure.getAttributes(). ...
        getNamedItem('number').getValue());
    % reset sharps/flats for new measure;
    currAccidentals = accidentalsForKey(currKey);
    % parse each measure element
    for j = 0:(measure.getLength()-1)
        switch char(measure.item(j).getNodeName())
            case 'attributes'
                [currKey, currBeats, currBeatType] = parseAttributes(measure.item(j));
                currAccidentals = accidentalsForKey(currKey);
            case 'note'
                [st, oc, d, a, v, o, s, ac] = parseNote(measure.item(j));
                if (~isnan(ac))
                    % Note indicated a change of accidentals.
                    currAccidentals = updateAccidentals(st, ac, currAccidentals);
                end
                if (o ~= 'g') % if the note isn't a grace note, include it in output
                    p = midiPitch(st, oc, currAccidentals);
                    if (o == '+' && a == 'l')
                        % if this note is linked with a tie, change
                        % duration of the previous note instead of
                        % including a new one.
                        mxml(ind-1, 2) = mxml(ind-1, 2) + d;
                        mxml(ind-1, 7) = mxml(ind-1, 7) + d*60.0/currTempo;
                    else
                        if currOrnam == 'n' % if there is no grace note to indicate
                            currOrnam = o; % indicated ornamentation is as parsed
                        end
                        mxml(ind, 1:4) = [beatCounter, d, 0, p];%, ...
                        mxml(ind, 5:7) = [  80, beatCounter*60.0/currTempo, d*60.0/currTempo];%, ...
                        mxml(ind, 8:11) = [   measureNum, currKey, currBeats, currBeatType];%, ...
                        mxml(ind, 12:17) = [   currDyn, beatCounter - currDynOnset, currWedge, a, v, currOrnam];%, ...
                        mxml(ind, 18:19) = [    (s == 1 || slurStarted == 1), isequal(s,1)];
                        currOrnam = 'n';
                        ind = ind + 1;
                    end
                    beatCounter = beatCounter + d;
                    slurStarted = s + slurStarted;
                else
                    currOrnam = o;
                end
            case 'direction'
                typeList = measure.item(j).getElementsByTagName('direction-type').item(0).getChildNodes();
                for k = 0:(typeList.getLength()-1)
                    type = typeList.item(k);
                    switch char(type.getNodeName())
                        case 'metronome'
                            unit = char(type.getElementsByTagName('beat-unit'). ...
                                item(0).getFirstChild().getNodeValue());
                            tempo = javaMethod('parseInt', 'java.lang.Integer', ...
                                type.getElementsByTagName('per-minute').item(0).getFirstChild().getNodeValue());
                            if (strcmp(unit, 'quarter'))
                                currTempo = tempo;
                            elseif (strcmp(unit, 'eighth'))
                                currTempo = tempo/2;
                            else
                                currTempo = tempo;
                            end
                        case 'dynamics'
                            dynNodes = type.getChildNodes();
                            currDyn = '0'; % unknown
                            for l = 0:(dynNodes.getLength()-1)
                                dyn = char(dynNodes.item(l).getNodeName());
                                if (strcmpi(dyn, 'fz') || strcmpi(dyn, 'sfz') || strcmpi(dyn, 'sf'))
                                    currDyn = 's';
                                elseif (strcmpi(dyn, 'fff'))
                                    currDyn = '9';
                                elseif (strcmpi(dyn, 'ff'))
                                    currDyn = '8';
                                elseif (strcmpi(dyn, 'f'))
                                    currDyn = '7';
                                elseif (strcmpi(dyn, 'mf'))
                                    currDyn = '6';
                                elseif (strcmpi(dyn, 'mp'))
                                    currDyn = '5';
                                elseif (strcmpi(dyn, 'p'))
                                    currDyn = '4';
                                elseif (strcmpi(dyn, 'pp'))
                                    currDyn = '3';
                                elseif (strcmpi(dyn, 'ppp'))
                                    currDyn = '2';
                                end
                            end
                            currDynOnset = beatCounter;
                        case 'wedge'
                            wt = char(type.getAttributes().getNamedItem('type').getValue());
                            switch wt
                                case 'stop'
                                    currWedge = 'n';
                                otherwise
                                    currWedge = wt(1);
                            end
                    end
                end
        end
    end
end



end

function accid = accidentalsForKey(fifths)
    fifthsMat = [0, 0, 0, 0, 0, 0, 0;
        0, 0, 0, 1, 0, 0, 0;
        1, 0, 0, 1, 0, 0, 0;
        1, 0, 0, 1, 1, 0, 0;
        1, 1, 0, 1, 1, 0, 0;
        1, 1, 0, 1, 1, 1, 0;
        1, 1, 1, 1, 1, 1, 0;
        1, 1, 1, 1, 1, 1, 1];
    
    if (fifths >= 0)
        accid = fifthsMat(fifths+1, :);
    else
        accid = fifthsMat(8+fifths,:) - 1;
    end
end

function acList = updateAccidentals(step, newAc, acList)
    if strcmpi('C', step)
        acList(1) = newAc;
    elseif strcmpi('D', step)
        acList(2) = newAc;
    elseif strcmpi('E', step)
        acList(3) = newAc;
    elseif strcmpi('F', step)
        acList(4) = newAc;
    elseif strcmpi('G', step)
        acList(5) = newAc;
    elseif strcmpi('A', step)
        acList(6) = newAc;
    elseif strcmpi('B', step)
        acList(7) = newAc;
    end
end

function p = midiPitch(step, octave, accid)
p = 12 + octave*12;
if strcmpi('C', step)
    p = p + accid(1);
elseif strcmpi('D', step)
    p = p + 2 + accid(2);
elseif strcmpi('E', step)
    p = p + 4 + accid(3);
elseif strcmpi('F', step)
    p = p + 5 + accid(4);
elseif strcmpi('G', step)
    p = p + 7 + accid(5);
elseif strcmpi('A', step)
    p = p + 9 + accid(6);
elseif strcmpi('B', step)
    p = p + 11 + accid(7);
else %rest
    p = 0;
end
end

function [step, octave, duration, art, vib, orn, slur, accid] = parseNote(note)
    nodes = note.getChildNodes();
    hasDot = 0;
    art = 'l'; % default: legato
    vib = 0;
    orn = 'n'; % default: no ornamentation
    slur = 0;
    step = NaN;
    accid = NaN;
    octave = 0;
    duration = 0;
    timeModNum = 1;
    timeModDen = 1;
    for i = 0:(nodes.getLength()-1)
        elmt = nodes.item(i);
        switch char(elmt.getNodeName())
            case 'pitch'
                step = char(elmt.getElementsByTagName( ...
                'step').item(0).getFirstChild().getNodeValue());
                octave = javaMethod('parseInt', 'java.lang.Integer', elmt.getElementsByTagName( ...
                'octave').item(0).getFirstChild().getNodeValue());
            case 'dot'
                hasDot = 1;
            case 'rest'
                step = 'rest';
            case 'tie'
                if (strcmpi('stop', ...
                        char(elmt.getAttributes().getNamedItem('type'). ...
                        getValue())))
                    orn = '+';
                end
            case 'type'
                switch char(elmt.getFirstChild().getNodeValue())
                    case 'whole'
                        duration = 4;
                    case 'half'
                        duration = 2;
                    case 'quarter'
                        duration = 1;
                    case 'eighth'
                        duration = 0.5;
                    case '16th'
                        duration = 0.25;
                    case '32nd'
                        duration = 0.125;
                end
            case 'time-modification'
                timeModNum = javaMethod('parseInt', 'java.lang.Integer', elmt.getElementsByTagName( ...
                'normal-notes').item(0).getFirstChild().getNodeValue());
                timeModDen = javaMethod('parseInt', 'java.lang.Integer', elmt.getElementsByTagName( ...
                'actual-notes').item(0).getFirstChild().getNodeValue());
            case 'accidental'
                switch char(elmt.getFirstChild().getNodeValue())
                    case 'sharp'
                        accid = 1;
                    case 'flat'
                        accid = -1;
                    case 'double-sharp'
                        accid = 2;
                    case 'double-flat'
                        accid = -2;
                    case 'natural'
                        accid = 0;
                end
            case 'grace'
                orn = 'g'; % todo: accacciatura or appogiatura
            case 'notations'
                nots = elmt.getChildNodes();
                for j = 0:(nots.getLength()-1)
                    switch char(nots.item(j).getNodeName())
                        case 'slur'
                            t = nots.item(j).getAttributes().getNamedItem( ...
                                'type').getValue();
                            if strcmpi(t, 'start')
                                slur = 1;
                            else % stop
                                slur = -1;
                            end
                        case 'articulations'
                            art = nots.item(j).getChildNodes();
                            if (art.getElementsByTagName('accent').getLength() > 0)
                                art = '<';
                            elseif (art.getElementsByTagName('staccato').getLength() > 0)
                                art = '.';
                            elseif (art.getElementsByTagName('tenuto').getLength() > 0)
                                art = '-';
                            else
                                art = 'l';
                            end
                        case 'technical'
                            % todo
                        case 'ornaments'
                            ornmt = nots.item(j).getChildNodes();
                            if (ornmt.getElementsByTagName('trill-mark').getLength() > 0)
                                orn = 't';
                            end
                    end
                end    
        end   
    end
    duration = duration *timeModNum/timeModDen;
    if hasDot
        duration = duration * 1.5;
    end
end

function [key, beat, beatType] = parseAttributes(attr)

    key = NaN;
    beat = NaN;
    beatType = NaN;

    % change of key
    k = attr.getElementsByTagName('key');
    if (k.getLength() > 0)
        fifths = k.item(0).getElementsByTagName('fifths');
        if (fifths.getLength() > 0)
            key = javaMethod('parseInt', 'java.lang.Integer', fifths.item(0).getFirstChild().getNodeValue());
        end
    end
    
    % change of time signature
    time = attr.getElementsByTagName('time');
    if (time.getLength() > 0)
        beats = time.item(0).getElementsByTagName('beats');
        if (beats.getLength() > 0)
            beat = javaMethod('parseInt', 'java.lang.Integer', beats.item(0).getFirstChild().getNodeValue());
        end
        beatType = time.item(0).getElementsByTagName('beat-type');
        if (beatType.getLength() > 0)
            beatType = javaMethod('parseInt', 'java.lang.Integer', beatType.item(0).getFirstChild().getNodeValue());
        end
    end
    
    % ignoring clef...
end