import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'button.dart';
import 'input.dart';

class SimpleTable extends StatefulWidget {
  final List<dynamic> dataList;
  final String? title;
  const SimpleTable({
    super.key,
    required this.dataList, this.title = '',
  });

  @override
  State<SimpleTable> createState() => _SimpleTableState();
}

class _SimpleTableState extends State<SimpleTable> {
  bool isEditing = false;
  int? editingIndex;
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  void _toggleEdit(int? index) {
    setState(() {
      isEditing = index != null;
      editingIndex = index;
      if (index != null) {
        nombreController.text = widget.dataList[index]['clave'] ?? '';
        descripcionController.text = widget.dataList[index]['descripcion'] ?? '';
      } else {
        nombreController.clear();
        descripcionController.clear();
        widget.dataList.removeWhere((element) => element['new'] == true && element['clave'].isEmpty);
      }
    });
  }

  void _saveEdit() {
    if (editingIndex != null && editingIndex! < widget.dataList.length) {
      widget.dataList[editingIndex!] = {
        'clave': nombreController.text,
        'descripcion': descripcionController.text,
      };
      _toggleEdit(null);
    }
  }

  void _addItem() {
    setState(() {
      widget.dataList.add({
        'clave': '',
        'descripcion': '',
        'new': true
      });
      isEditing = true;
      editingIndex = widget.dataList.length - 1;
    });
  }

  void _removeItem({required int index}){
    widget.dataList.removeAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(widget.title!.isNotEmpty)...[
          Text(widget.title!, style: AppTheme.light.title2,),
          const SizedBox(height: 5,)
        ],
        Container(
          height: 400,
          width: 600,
          decoration: BoxDecoration(
              color: AppTheme.light.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18)
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Text('Clave', style: AppTheme.light.bodyBold,)
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                      flex: 2,
                      child: Text('Descripción', style: AppTheme.light.bodyBold,)
                  ),
                  const Spacer(),
                  Button(
                    width: 130,
                    text: 'Agregar',
                    icon: Icons.add_box_outlined,
                    onPressed: _addItem,
                  )
                ],
              ),
              const SizedBox(height: 5,),
              const Divider(),
              const SizedBox(height: 5,),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.dataList.length,
                  itemBuilder:  (context, index) {
                    dynamic item = widget.dataList[index];
                    final bool isCurrentEditing = isEditing && editingIndex == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1,
                            child: isCurrentEditing
                                ? Input(
                              controller: nombreController,
                              labelText: 'Clave',
                            )
                                : Text(item['clave'] ?? '', style: AppTheme.light.body),
                          ),
                          const SizedBox(width: 10,),
                          // Description Field
                          Expanded(
                            flex: 2,
                            child: isCurrentEditing
                                ? Input(
                              controller: descripcionController,
                              labelText: 'Descripción',
                            )
                                : Text(item['descripcion'] ?? '', style: AppTheme.light.body),
                          ),
                          // Action Buttons
                          SizedBox(
                            width: 90,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if(!isEditing)...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.black, size: 25,),
                                    onPressed: () => _toggleEdit(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.black, size: 25,),
                                    onPressed: () => _removeItem(index: index),
                                  ),
                                ],
                                if(isCurrentEditing)...[
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 25,),
                                    onPressed: _saveEdit,
                                  ),
                                  const SizedBox(width: 5,),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.black,size: 25,),
                                    onPressed: () => _toggleEdit(null),
                                  ),
                                ]
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}