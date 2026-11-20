
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const Src4App());

class Question {
  final int id;
  final String category, question, explanation;
  final List<String> options;
  final int answer;
  Question.fromJson(Map<String, dynamic> j)
      : id=j['id'], category=j['category'], question=j['question'],
        explanation=j['explanation'], options=List<String>.from(j['options']),
        answer=j['answer'];
}

class Src4App extends StatelessWidget {
  const Src4App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SRC4 Sınav Hazırlık', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1769aa)),
      scaffoldBackgroundColor: const Color(0xfff4f7fb), fontFamily: 'Roboto'),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage> {
  List<Question> questions=[];
  Set<int> answered={}, wrong={}, correct={};
  Map<int,int> attempts={};
  int cursor=0;
  int reviewCursor=0;
  bool loading=true;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final raw=await rootBundle.loadString('assets/questions.json');
    questions=(jsonDecode(raw) as List).map((e)=>Question.fromJson(e)).toList();
    final p=await SharedPreferences.getInstance();
    answered=(p.getStringList('answered')??[]).map(int.parse).toSet();
    wrong=(p.getStringList('wrong')??[]).map(int.parse).toSet();
    correct=(p.getStringList('correct')??[]).map(int.parse).toSet();
    cursor=p.getInt('cursor')??0;
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _save() async {
    final p=await SharedPreferences.getInstance();
    await p.setStringList('answered',answered.map((e)=>'$e').toList());
    await p.setStringList('wrong',wrong.map((e)=>'$e').toList());
    await p.setStringList('correct',correct.map((e)=>'$e').toList());
    await p.setInt('cursor',cursor);
  }
  void _openQuestion({bool review=false}) {
    if(questions.isEmpty)return;
    Question q;
    if(review){
      if(wrong.isEmpty){_message('Tekrar çözülecek yanlış soru yok.');return;}
      final reviewList=questions.where((e)=>wrong.contains(e.id)).toList();
      q=reviewList[reviewCursor%reviewList.length];
      reviewCursor++;
    } else {
      if(answered.length>=questions.length){_message('Tebrikler! 250 sorunun tamamını çözdün. Yanlışlarını tekrar edebilirsin.');return;}
      int index=cursor%questions.length;
      while(answered.contains(questions[index].id) && answered.length<questions.length){
        index=(index+1)%questions.length;
      }
      q=questions[index];
    }
    Navigator.push(context,MaterialPageRoute(builder:(_)=>QuestionPage(
      question:q, review:review, onAnswered:(isCorrect){
        setState((){
          answered.add(q.id);
          if(isCorrect){correct.add(q.id);wrong.remove(q.id);}
          else {wrong.add(q.id);correct.remove(q.id);}
          if(!review) cursor=(q.id)%questions.length;
        });
        _save();
      }, onNext:(){
        if(!review){setState(()=>cursor=(q.id)%questions.length);_save();}
        Navigator.pop(context);
      },
    )));
  }
  void _message(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final done=answered.length, pct=done==0?0:(correct.length/done*100).round();
    return Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const SizedBox(height:8),
      Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:BoxDecoration(
        gradient:const LinearGradient(colors:[Color(0xff102f46),Color(0xff1769aa)]),
        borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('SRC4 SINAV HAZIRLIK',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.bold,letterSpacing:1.2)),
          const SizedBox(height:18),const Text('Öner',style:TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),const Text('Yurtiçi eşya-kargo taşımacılığı',style:TextStyle(color:Colors.white70)),
          const SizedBox(height:20),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
            Text('$done / 250 soru',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
            Text('%$pct başarı',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600))]),
          const SizedBox(height:9),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(
            value:done/250,minHeight:9,backgroundColor:Colors.white24,color:Colors.lightGreenAccent)),
        ])),
      const SizedBox(height:22),
      _tile(Icons.insights,'İstatistikler','Başarı oranını ve gelişimini incele',const Color(0xff2479b9),()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StatsPage(answered:answered,correct:correct,wrong:wrong,questions:questions)))),
      const SizedBox(height:12),
      _tile(Icons.refresh,'Yanlışlar','Yanlış cevapladığın soruları yeniden çöz',const Color(0xffd64b4b),()=>_openQuestion(review:true),badge:'${wrong.length}'),
      const Spacer(),
      SizedBox(width:double.infinity,height:60,child:FilledButton.icon(
        onPressed:()=>_openQuestion(),icon:const Icon(Icons.play_arrow_rounded),label:const Text('Devam',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        style:FilledButton.styleFrom(backgroundColor:const Color(0xff1769aa),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))))),
      const SizedBox(height:8),Center(child:Text('250 özgün çalışma sorusu • Çevrimdışı kullanım',style:TextStyle(color:Colors.grey.shade600,fontSize:11))),
    ]))));
  }
  Widget _tile(IconData icon,String title,String sub,Color color,VoidCallback tap,{String? badge})=>Material(
    color:Colors.white,borderRadius:BorderRadius.circular(18),child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(18),
      child:Padding(padding:const EdgeInsets.all(17),child:Row(children:[
        CircleAvatar(backgroundColor:color.withOpacity(.12),child:Icon(icon,color:color)),
        const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
          const SizedBox(height:3),Text(sub,style:TextStyle(color:Colors.grey.shade600,fontSize:12))])),
        if(badge!=null)Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(20)),child:Text(badge,style:TextStyle(color:color,fontWeight:FontWeight.bold))),
        const Icon(Icons.chevron_right,color:Colors.grey)
      ]))));
}

class QuestionPage extends StatefulWidget {
  final Question question; final bool review;
  final ValueChanged<bool> onAnswered; final VoidCallback onNext;
  const QuestionPage({super.key,required this.question,required this.review,required this.onAnswered,required this.onNext});
  @override State<QuestionPage> createState()=>_QuestionPageState();
}
class _QuestionPageState extends State<QuestionPage>{
  int? selected; bool submitted=false;
  @override Widget build(BuildContext context){
    final q=widget.question;
    return Scaffold(appBar:AppBar(title:Text(widget.review?'Yanlışları tekrar çöz':'SRC4 • Soru ${q.id}'),backgroundColor:const Color(0xfff4f7fb)),
      body:SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(q.category.toUpperCase(),style:const TextStyle(color:Color(0xff1769aa),fontWeight:FontWeight.bold,fontSize:11,letterSpacing:.7)),
        const SizedBox(height:14),Text(q.question,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700,height:1.35)),
        const SizedBox(height:22),
        ...List.generate(q.options.length,(i){
          final isRight=i==q.answer, isSelected=selected==i;
          Color? bg; Color border=Colors.grey.shade300; Color? fg;
          if(submitted&&isRight){bg=Colors.green.withOpacity(.12);border=Colors.green;fg=Colors.green.shade800;}
          else if(submitted&&isSelected&&!isRight){bg=Colors.red.withOpacity(.10);border=Colors.red;fg=Colors.red.shade800;}
          else if(isSelected){bg=const Color(0xff1769aa).withOpacity(.08);border=const Color(0xff1769aa);}
          return Padding(padding:const EdgeInsets.only(bottom:11),child:InkWell(
            onTap:submitted?null:()=>setState(()=>selected=i),borderRadius:BorderRadius.circular(14),
            child:Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:bg??Colors.white,border:Border.all(color:border,width:1.4),borderRadius:BorderRadius.circular(14)),
              child:Row(children:[CircleAvatar(radius:14,backgroundColor:(fg??Colors.blueGrey).withOpacity(.12),child:Text(String.fromCharCode(65+i),style:TextStyle(color:fg??Colors.blueGrey,fontWeight:FontWeight.bold,fontSize:12))),const SizedBox(width:12),Expanded(child:Text(q.options[i],style:TextStyle(fontWeight:isSelected?FontWeight.w600:FontWeight.normal,color:fg))),if(submitted&&isRight)const Icon(Icons.check_circle,color:Colors.green),if(submitted&&isSelected&&!isRight)const Icon(Icons.cancel,color:Colors.red)]))
          ));
        }),
        if(submitted)Container(width:double.infinity,padding:const EdgeInsets.all(16),margin:const EdgeInsets.only(top:5),decoration:BoxDecoration(color:Colors.blueGrey.withOpacity(.07),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(selected==q.answer?'Doğru cevap!':'Doğru cevap: ${q.options[q.answer]}',style:TextStyle(fontWeight:FontWeight.bold,color:selected==q.answer?Colors.green.shade700:Colors.red.shade700)),
          const SizedBox(height:7),Text(q.explanation,style:const TextStyle(height:1.35))
        ])),
        const Spacer(),
        SizedBox(width:double.infinity,height:54,child:FilledButton(
          onPressed:submitted?widget.onNext:selected==null?null:(){
            setState(()=>submitted=true);widget.onAnswered(selected==q.answer);
          },child:Text(submitted?'Sonraki soru':'Cevabı kontrol et',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold))))
      ]))));
  }
}

class StatsPage extends StatelessWidget {
  final Set<int> answered,correct,wrong; final List<Question> questions;
  const StatsPage({super.key,required this.answered,required this.correct,required this.wrong,required this.questions});
  @override Widget build(BuildContext context){
    final total=answered.length, rate=total==0?0:correct.length/total;
    final cats=questions.map((e)=>e.category).toSet().toList();
    return Scaffold(appBar:AppBar(title:const Text('İstatistikler')),body:ListView(padding:const EdgeInsets.all(18),children:[
      Row(children:[
        _stat('Çözülen', '$total / 250', Icons.quiz,Colors.blue),
        const SizedBox(width:10),_stat('Doğru', '${correct.length}',Icons.check_circle,Colors.green),
        const SizedBox(width:10),_stat('Yanlış', '${wrong.length}',Icons.cancel,Colors.red),
      ]),
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Başarı oranı',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        const SizedBox(height:12),Text('%${(rate*100).round()}',style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800,color:Color(0xff1769aa))),
        ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:rate,minHeight:10,color:Colors.green,backgroundColor:Colors.grey.shade200)),
        const SizedBox(height:8),Text(total==0?'İlk sorunu çözerek istatistiklerini oluşturmaya başla.':rate>=.8?'Harika gidiyorsun! Sınav temposunu koru.':rate>=.5?'İyi ilerliyorsun; yanlışlarına tekrar dön.':'Başlangıç çizgisindesin. Düzenli tekrar başarıyı artırır.',style:TextStyle(color:Colors.grey.shade700))
      ]))),
      const SizedBox(height:14),const Text('Konu bazında ilerleme',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      ...cats.map((c){
        final ids=questions.where((q)=>q.category==c).map((q)=>q.id).toSet();
        final n=answered.intersection(ids).length, good=correct.intersection(ids).length;
        final value=n==0?0:good/n;
        return Card(child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text(c,style:const TextStyle(fontWeight:FontWeight.w600))),Text('$good / $n doğru',style:const TextStyle(color:Colors.blueGrey,fontSize:12))]),
          const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(value:value,minHeight:7,color:Colors.teal,backgroundColor:Colors.grey.shade200))
        ])));
      }),
      const SizedBox(height:12),const Text('Mini başarı rozetleri',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      Wrap(spacing:8,runSpacing:8,children:[
        _badge('🚚 İlk adım',total>=1),_badge('🎯 10 soru',total>=10),_badge('🔥 50 soru',total>=50),_badge('🏆 100 soru',total>=100),_badge('💯 80% başarı',rate>=.8&&total>=10)
      ]),
      const SizedBox(height:16),Text('Not: Grafikler ve başarı oranları bu cihazdaki cevap geçmişine göre hesaplanır.',style:TextStyle(color:Colors.grey.shade600,fontSize:12))
    ]));
  }
  Widget _stat(String label,String value,IconData icon,Color color)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:16,horizontal:8),child:Column(children:[Icon(icon,color:color),const SizedBox(height:8),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),Text(label,style:const TextStyle(fontSize:11,color:Colors.blueGrey))]))));
  Widget _badge(String label,bool active)=>Chip(avatar:Icon(active?Icons.verified:Icons.lock_outline,size:17,color:active?Colors.green:Colors.grey),label:Text(label),backgroundColor:active?Colors.green.withOpacity(.10):Colors.grey.shade200);
}
