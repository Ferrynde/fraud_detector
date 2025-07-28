import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DocumentFraudDetector extends StatefulWidget {
  @override
  _DocumentFraudDetectorState createState() => _DocumentFraudDetectorState();
}

class _DocumentFraudDetectorState extends State<DocumentFraudDetector> {
  File? _image;
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  Future pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: src);
    if (img != null) {
      setState(() {
        _image = File(img.path);
        _result = null; // Reset result when new image is selected
      });
    }
  }

  Future uploadAndPredict() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Remplacez par l'IP de votre serveur
      final uri = Uri.parse('http://192.168.1.180:5000/predict');
      var req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', _image!.path));
      
      var res = await req.send();
      
      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(await res.stream.bytesToString());
        setState(() => _result = jsonRes);
      } else {
        setState(() => _result = {'error': 'Erreur serveur: ${res.statusCode}'});
      }
    } catch (e) {
      setState(() => _result = {'error': 'Erreur de connexion: $e'});
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResultWidget() {
    if (_result == null) return Container();
    
    if (_result!.containsKey('error')) {
      return Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          _result!['error'],
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    bool isFraud = _result!['fraud'] ?? false;
    double prediction = _result!['prediction'] ?? 0.0;
    double confidence = (prediction * 100);

    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isFraud 
            ? Colors.red.withOpacity(0.1) 
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFraud ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isFraud ? Icons.warning : Icons.verified,
            size: 48,
            color: isFraud ? Colors.red : Colors.green,
          ),
          SizedBox(height: 12),
          Text(
            isFraud ? 'DOCUMENT SUSPECT' : 'DOCUMENT AUTHENTIQUE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isFraud ? Colors.red[700] : Colors.green[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Score de confiance: ${confidence.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isFraud ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fe-Detect - Détecteur de Fraude'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone d'affichage de l'image
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune image sélectionnée',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            SizedBox(height: 20),
            
            // Boutons de sélection d'image
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Caméra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Bouton d'analyse
            ElevatedButton(
              onPressed: _isLoading ? null : uploadAndPredict,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analyse en cours...'),
                      ],
                    )
                  : Text(
                      'Analyser le document',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            
            // Zone de résultats
            _buildResultWidget(),
          ],
        ),
      ),
    );
  }
}