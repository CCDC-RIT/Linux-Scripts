#!/bin/bash

echo "---------------------- Namespaces ------------------------"
kubectl describe ns

echo ""
echo "------------------------- Nodes --------------------------"
kubectl get --all-namespaces nodes -o wide

echo ""
echo "---------------------- Deployments -----------------------"
kubectl get --all-namespaces deployments

echo ""
echo "-------------------------- Pods --------------------------"
kubectl get --all-namespaces pods -o wide
kubectl describe --all-namespaces pods > pods.txt
echo ""
echo "More details about pods can be found in the newly created pods.txt"
