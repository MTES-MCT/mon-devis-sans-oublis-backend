-- Script de nettoyage du schéma export_anonymized dans la DB source
-- Ce script supprime le schéma temporaire créé pour l'anonymisation

DROP SCHEMA IF EXISTS export_anonymized CASCADE;