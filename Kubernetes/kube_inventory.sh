#!/bin/bash

echo "---------------------- Namespaces ------------------------"
kubectl describe ns

echo ""
echo "------------------------- Nodes --------------------------"
kubectl get --all-namespaces nodes -o wide

echo ""
echo "-------------------------- Pods --------------------------"
kubectl get --all-namespaces pods -o wide
