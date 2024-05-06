function [posint, vel] = process_fictrac_signal(posint, numframes, rateim, ratedaq, ratefictrac, maxvolt, maxFlyVelocity)

posint = posint  / maxvolt * 2*pi - pi; %put in range -pi to pi, G4 frame 0 assigned to -pi
