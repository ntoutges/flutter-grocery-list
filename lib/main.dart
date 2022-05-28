import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "dart:math";

const preferenceNameKey = "groceryListName";
const preferenceCountKey = "groceryListCount";

void main() {
  runApp(const GroceryListApp());
}

class GroceryListApp extends StatelessWidget {
  const GroceryListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Grocery List",
      home: GroceryListPage(),
    );
  }
}

class GroceryListPage extends StatelessWidget {
  const GroceryListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        var cubit = GroceryListCubit();
        cubit.initPreferences();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Grocery List")),
        body: const GroceryListView(),
      ),
    );
  }
}

class GroceryListView extends StatelessWidget {
  const GroceryListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroceryListCubit, GroceryListState>(
      builder: (blocContext, state) {
        return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: (state.getItems().length + 1) * 2,
            itemBuilder: (context, i) {
              if (i.isOdd) return const Divider();
              final index = i ~/ 2;
              if (index < state.getItems().length) {
                // show item in list
                return ListTile(
                  title: TextField(
                    onChanged: (String? value) {
                      String nameValue = "";
                      if (value != null) {
                        nameValue = value;
                      }
                      blocContext
                          .read<GroceryListCubit>()
                          .setGroceryName(index, nameValue);
                    },
                    controller: TextEditingController(
                        text: state.getItems()[index].getName()),
                    autofocus: index == state.getPrevItemLength(),
                  ),
                  trailing: Wrap(
                    spacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: 50.0,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: state.getItems()[index].getCount()),
                          textAlign: TextAlign.center,
                          onChanged: (String? value) {
                            String nameValue = "0";
                            if (value != null) {
                              nameValue = value;
                            }
                            blocContext
                                .read<GroceryListCubit>()
                                .setGroceryCount(index, nameValue);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          blocContext
                              .read<GroceryListCubit>()
                              .removeGroceryItem(index);
                        },
                      )
                    ],
                  ),
                );
              } else {
                // show 'add item' prompt
                return ListTile(
                  title: const Text(
                    "Add Item",
                    textAlign: TextAlign.center,
                  ),
                  tileColor: Colors.deepOrange,
                  onTap: () {
                    blocContext.read<GroceryListCubit>().addGroceryItem();
                  },
                );
              }
            });
      },
    );
  }
}

class GroceryListCubit extends Cubit<GroceryListState> {
  GroceryListCubit() : super(GroceryListState([], -1));

  void initPreferences() {
    state.setInitCallback(() {
      emit(state); // update screen
    });
  }

  void addGroceryItem() {
    var newItemList = state.getItems().toList(); // copy list
    newItemList.add(GroceryItem("", "0"));
    var newState = GroceryListState(
        newItemList, state.getItems().length, state.getSavedPrefs());
    // state.getItems().add(GroceryItem("", "0"));
    emit(newState);
  }

  void removeGroceryItem(int index) {
    var newItemList = state.getItems().toList(); // copy list
    newItemList.removeAt(index);
    var newState = GroceryListState(
        newItemList, state.getItems().length, state.getSavedPrefs());
    // state.getItems().removeAt(index);
    emit(newState);
  }

  void setGroceryName(int index, String name) {
    state.getItems()[index].setName(name);
    savePreferenceData();
    // emit(state); // no screen update required
  }

  void setGroceryCount(int index, String count) {
    state.getItems()[index].setCount(count);
    savePreferenceData();
    // emit(state); // no screen update required
  }

  void savePreferenceData() {
    state.getSavedPrefs()?.saveItems(state.getItems());
  }
}

class GroceryListState /* extends Equatable */ {
  // don't extend equatable to force bloc update every time
  final List<GroceryItem> _items;
  final int _prevItemLength;
  SavedPreferenceData? _savedPreferences;
  bool isInitialized = false;
  var _initCallback;

  GroceryListState(this._items, this._prevItemLength,
      [SavedPreferenceData? savedPreferences, callback]) {
    if (savedPreferences == null) {
      // should only run on app startup
      _savedPreferences = SavedPreferenceData(
        () {
          final savedPreferences = _savedPreferences;
          if (savedPreferences != null) {
            _items.addAll(savedPreferences.getItems());
          }
          isInitialized = true;
          if (_initCallback != null) {
            _initCallback();
          }
        },
      );
    } else {
      _savedPreferences = savedPreferences;
      _savedPreferences?.saveItems(_items);
      isInitialized = true;
      if (_initCallback != null) {
        _initCallback();
      }
    }
  }
  List<GroceryItem> getItems() {
    return _items;
  }

  int getPrevItemLength() {
    return _prevItemLength;
  }

  SavedPreferenceData? getSavedPrefs() {
    return _savedPreferences;
  }

  void setInitCallback(callback) {
    if (isInitialized) {
      callback();
    } else {
      _initCallback = callback;
    }
  }

//   @override
//   List<Object> get props => [
//         _items.length,
//         _prevItemLength
//       ]; // using [_items.length] as a property, as equatable (to my knowledge) cannot handle checking lists
}

class SavedPreferenceData {
  SharedPreferences? _saveData;
  var _nameList = <String>[];
  var _countList = <String>[];
  SavedPreferenceData(callback) {
    (() async {
      _saveData = await SharedPreferences.getInstance();
      final nameList = _saveData?.getStringList(preferenceNameKey);
      final countList = _saveData?.getStringList(preferenceCountKey);
      if (nameList != null) {
        _nameList = nameList;
      }
      if (countList != null) {
        _countList = countList;
      }
      callback();
    })();
  }
  List<GroceryItem> getItems() {
    final List<GroceryItem> items = [];
    for (int i = 0; i < min(_nameList.length, _countList.length); i++) {
      items.add(GroceryItem(_nameList[i], _countList[i]));
    }
    // these are no longer required to be saved, so this (hopefully) saves some memory
    _nameList = [];
    _countList = [];

    return items;
  }

  void saveItems(List<GroceryItem> items) {
    _nameList = [];
    _countList = [];
    for (var i = 0; i < items.length; i++) {
      _nameList.add(items[i].getName());
      _countList.add(items[i].getCount());
    }
    _saveData?.setStringList(preferenceNameKey, _nameList);
    _saveData?.setStringList(preferenceCountKey, _countList);
  }
}

class GroceryItem {
  String name = "";
  String count = "0";
  GroceryItem(this.name, this.count);
  String getName() {
    return name;
  }

  String getCount() {
    return count;
  }

  void setName(name) {
    this.name = name;
  }

  void setCount(String count) {
    this.count = count;
  }
}
